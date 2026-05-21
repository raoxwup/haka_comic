import 'dart:async';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/search/search_cache.dart';

/// 滑动窗口限速器：保证 1 秒内最多 AppConf().maxRequestsPerSecond 个请求
///
/// 由 search_probe.dart 持有，search_comics.dart 通过导入共享同一实例。
/// maxPerSecond 动态读取 AppConf，用户修改设置后立即生效。
class SearchRateLimiter {
  final List<DateTime> _timestamps = [];

  Future<void> wait() async {
    final maxPerSecond = AppConf().maxRequestsPerSecond;
    final now = DateTime.now();
    // 清除已滑出 1 秒窗口的记录
    _timestamps.removeWhere(
      (t) => now.difference(t) >= const Duration(seconds: 1),
    );

    if (_timestamps.length >= maxPerSecond) {
      // 窗口已满，等到最早的那个请求滑出
      final waitMs =
          const Duration(seconds: 1) - now.difference(_timestamps.first);
      if (waitMs > Duration.zero) {
        await Future.delayed(waitMs);
      }
      _timestamps.removeAt(0);
    }
    _timestamps.add(DateTime.now());
  }
}

/// 全局搜索限速器实例（probe + autoFill 共享）
final searchLimiter = SearchRateLimiter();

/// 探测候选词的 total，返回 (最快关键词, 其 page1 结果)
///
/// **抢先返回策略**：第一个响应的候选词立即返回，不等其余。
/// 后续更优候选词通过 [onSlowerCandidate] 回调通知调用方。
///
/// - 全部缓存命中 → 直接返回最优（零延迟）
/// - 部分缓存命中 → 返回缓存中最优，后台探测其余
/// - 全部未命中 → 并行探测，第一个返回即用
/// - [onSlowerCandidate] 每当一个更慢的候选词返回时调用，
///   调用方可据此决定是否切换关键词
Future<(String, SearchResponse?)> probeOptimalKeyword({
  required List<String> candidates,
  required ComicSortType sortType,
  required List<String> categories,
  required String Function(String) normalizeKeyword,
  void Function(String keyword, int total, SearchResponse? response)?
      onSlowerCandidate,
}) async {
  Log.i('[Probe]', 'start candidates=$candidates sort=$sortType');

  // 单候选词 → 直接请求，无需探测
  if (candidates.length == 1) {
    final kw = normalizeKeyword(candidates.first);
    Log.i('[Probe]', 'single candidate, direct search: $kw');
    final payload = SearchPayload(
      keyword: kw,
      page: 1,
      sort: sortType,
      categories: categories,
    );
    try {
      final resp = await searchComics(payload);
      SearchProbeCache.put(kw, categories, resp.comics.total);
      final ck = SearchCache.buildKey(kw, sortType, categories);
      SearchCache.put(ck, 1, resp);
      Log.i('[Probe]', 'single done: $kw total=${resp.comics.total}');
      return (kw, resp);
    } catch (e) {
      Log.e('[Probe]', error: 'single search failed: $kw');
      return (kw, null);
    }
  }

  // 多候选词：先查 probe 缓存，再对 miss 的词并行探测
  final normalized = candidates.map(normalizeKeyword).toList();

  final cacheTotals = <String, int>{};
  final toProbe = <String>[];

  for (final kw in normalized) {
    final cached = SearchProbeCache.get(kw, categories);
    if (cached != null) {
      cacheTotals[kw] = cached;
      Log.i('[Probe]', 'cache HIT: $kw total=$cached');
    } else {
      toProbe.add(kw);
      Log.i('[Probe]', 'cache MISS: $kw');
    }
  }

  // ── 全部命中缓存 → 直接返回最优 ─────────
  if (toProbe.isEmpty) {
    Log.i('[Probe]', 'all cached, returning best');
    final best = cacheTotals.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    return (best.key, null);
  }

  // ── 部分命中缓存 → 返回缓存中最优，后台探测其余 ─────────
  if (cacheTotals.isNotEmpty) {
    final bestCached = cacheTotals.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    Log.i('[Probe]',
        'partial cache: bestCached=${bestCached.key} total=${bestCached.value}, '
        'probing ${toProbe.length} uncached in background');

    // 后台探测未缓存的候选词，完成后通过 onSlowerCandidate 通知
    unawaited(_probeInBackground(
      toProbe, sortType, categories, onSlowerCandidate,
    ));

    return (bestCached.key, null);
  }

  // ── 全部未命中 → 并行探测，第一个成功即返回，其余后台通知 ─────────
  Log.i('[Probe]',
      'all miss, probing ${toProbe.length} keywords (first-to-complete wins)');
  final completer = Completer<(String, int, SearchResponse?)>();
  var probeCompleted = 0;

  for (final kw in toProbe) {
    final payload = SearchPayload(
      keyword: kw,
      page: 1,
      sort: sortType,
      categories: categories,
    );
    searchComics(payload).then((resp) {
      SearchProbeCache.put(kw, categories, resp.comics.total);
      final ck = SearchCache.buildKey(kw, sortType, categories);
      SearchCache.put(ck, 1, resp);
      Log.i('[Probe]', '  ✓ $kw total=${resp.comics.total}');
      probeCompleted++;
      if (!completer.isCompleted) {
        // 第一个成功 → 立即返回
        completer.complete((kw, resp.comics.total, resp));
      } else {
        // 后续 → 通知调用方
        onSlowerCandidate?.call(kw, resp.comics.total, resp);
      }
    }).catchError((e) {
      Log.e('[Probe]', error: '  ✗ $kw failed: $e');
      probeCompleted++;
      // 全部失败且 completer 未完成 → 用此词兜底
      if (!completer.isCompleted &&
          probeCompleted >= toProbe.length) {
        completer.complete((kw, 999999, null));
      }
    });
  }

  final (winner, winnerTotal, winnerResp) = await completer.future;
  Log.i('[Probe]', 'fast winner: $winner total=$winnerTotal');
  return (winner, winnerResp);
}

/// 后台并行探测（用于部分缓存命中场景）
Future<void> _probeInBackground(
  List<String> toProbe,
  ComicSortType sortType,
  List<String> categories,
  void Function(String keyword, int total, SearchResponse? response)?
      onSlowerCandidate,
) async {
  await Future.wait(toProbe.map((kw) async {
    final payload = SearchPayload(
      keyword: kw,
      page: 1,
      sort: sortType,
      categories: categories,
    );
    try {
      final resp = await searchComics(payload);
      SearchProbeCache.put(kw, categories, resp.comics.total);
      Log.i('[Probe]', '  background ✓ $kw total=${resp.comics.total}');
      onSlowerCandidate?.call(kw, resp.comics.total, resp);
    } catch (e) {
      Log.e('[Probe]', error: '  background ✗ $kw failed: $e');
    }
  }));
}

// ═══════════════════════════════════════
// ProbeCache（TTL 30min + LRU 100）
// ═══════════════════════════════════════

/// 关键词 total 探测缓存（TTL 淘汰）
///
/// key = normalizedKeyword|categories（total 受分类筛选影响，不受 sort 影响）
/// value = (total, 探测时间)
/// 容量：100 条，LRU 淘汰
/// TTL：30 分钟（total 变化缓慢，半小时覆盖一次会话）
class SearchProbeCache {
  static const int _maxSize = 100;
  static const Duration _ttl = Duration(minutes: 30);

  static final Map<String, _ProbeEntry> _cache = {};
  static final List<String> _keys = []; // LRU 顺序

  static String buildKey(String normalizedKeyword, List<String> categories) {
    return '$normalizedKeyword|${categories.join(",")}';
  }

  /// 查询缓存中的 total，过期视为 miss
  static int? get(String normalizedKeyword, List<String> categories) {
    final key = buildKey(normalizedKeyword, categories);
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.time) > _ttl) {
      _cache.remove(key);
      _keys.remove(key);
      return null;
    }
    _keys.remove(key);
    _keys.add(key);
    return entry.total;
  }

  /// 写入探测结果
  static void put(String normalizedKeyword, List<String> categories, int total) {
    final key = buildKey(normalizedKeyword, categories);
    if (!_cache.containsKey(key)) {
      if (_cache.length >= _maxSize) {
        final evict = _keys.removeAt(0);
        _cache.remove(evict);
      }
    }
    _cache[key] = _ProbeEntry(total, DateTime.now());
    _keys.remove(key);
    _keys.add(key);
  }

  /// 清空缓存
  static void clear() {
    _cache.clear();
    _keys.clear();
  }
}

class _ProbeEntry {
  final int total;
  final DateTime time;
  _ProbeEntry(this.total, this.time);
}
