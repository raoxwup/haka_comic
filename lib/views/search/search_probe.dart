import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
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

/// 探测候选词的 total，返回 (最优关键词, 其 page1 结果)
///
/// - 优先从 [SearchProbeCache] 读取 total（零网络开销）
/// - 仅对 cache miss 的词发起网络请求（受 [_searchLimiter] 限速）
/// - 只把 best 关键词的 page 1 写入 [SearchCache]
/// - 单候选词直接请求（不走探测逻辑）
Future<(String, SearchResponse?)> probeOptimalKeyword({
  required List<String> candidates,
  required ComicSortType sortType,
  required List<String> categories,
  required String Function(String) normalizeKeyword,
}) async {
  // 单候选词 → 直接请求，无需探测
  if (candidates.length == 1) {
    final kw = normalizeKeyword(candidates.first);
    await searchLimiter.wait();
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
      return (kw, resp);
    } catch (_) {
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
    } else {
      toProbe.add(kw);
    }
  }

  // 滑动窗口限速：1 秒内最多 maxRequestsPerSecond 个请求
  final probeResponses = <String, SearchResponse>{};
  if (toProbe.isNotEmpty) {
    await Future.wait(toProbe.map((kw) async {
      await searchLimiter.wait();
      final payload = SearchPayload(
        keyword: kw,
        page: 1,
        sort: sortType,
        categories: categories,
      );
      try {
        final resp = await searchComics(payload);
        cacheTotals[kw] = resp.comics.total;
        SearchProbeCache.put(kw, categories, resp.comics.total);
        probeResponses[kw] = resp;
      } catch (_) {}
    }));
  }

  // 选 total 最小的词（缩小范围减少流量）
  if (cacheTotals.isEmpty) {
    return (normalized.first, null);
  }

  final best = cacheTotals.entries.reduce(
    (a, b) => a.value <= b.value ? a : b,
  );

  // 只把 best 关键词的 page 1 写入 SearchCache
  final bestResp = probeResponses[best.key];
  if (bestResp != null) {
    final ck = SearchCache.buildKey(best.key, sortType, categories);
    SearchCache.put(ck, 1, bestResp);
  }

  return (best.key, bestResp);
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
