import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';

/// 搜索结果 API 级多页缓存（LFU with Aging 淘汰策略）
///
/// 外层键: normalizedKeyword|sort|categories（不含 page）
/// 内层键: page → SearchResponse
/// 淘汰策略: 每条目独立生命值，命中 +1、其余 -1，归零淘汰
/// 容量兜底: LRU 200 条
class SearchCache {
  static const int _maxSize = 200;
  static const int _initialLife = 5;

  static final Map<String, Map<int, SearchResponse>> _cache = {};
  static final List<String> _keys = [];
  static final Map<String, int> _life = {};

  /// 构建缓存外层键（不含 page）
  static String buildKey(
    String normalizedKeyword,
    ComicSortType sort,
    List<String> categories,
  ) {
    return '$normalizedKeyword|${sort.name}|${categories.join(',')}';
  }

  /// 条目是否存在且生命值 > 0
  static bool contains(String key) {
    return _cache.containsKey(key) && ((_life[key] ?? 0) > 0);
  }

  /// 获取指定页的缓存数据
  static SearchResponse? get(String key, int page) {
    return _cache[key]?[page];
  }

  /// 获取某搜索条件下已缓存的页码列表
  static List<int> getCachedPages(String key) {
    return _cache[key]?.keys.toList() ?? [];
  }

  /// 命中续命：该条目 +1，其余全部 -1，归零者淘汰
  static void touch(String key) {
    _life[key] = (_life[key] ?? _initialLife) + 1;
    _keys.remove(key);
    _keys.add(key);

    // 其余条目 -1，归零淘汰
    final toRemove = <String>[];
    for (final k in _life.keys) {
      if (k == key) continue;
      _life[k] = (_life[k] ?? 0) - 1;
      if (_life[k]! <= 0) toRemove.add(k);
    }
    if (toRemove.isNotEmpty) {
      Log.d('Cache LFU evict', '${toRemove.length} entries');
    }
    for (final k in toRemove) {
      _cache.remove(k);
      _keys.remove(k);
      _life.remove(k);
    }
  }

  /// 写入缓存（LRU 顺序维护，新条目生命值 = 5）
  static void put(String key, int page, SearchResponse data) {
    if (!_cache.containsKey(key)) {
      if (_cache.length >= _maxSize) {
        final evict = _keys.removeAt(0);
        Log.d('Cache LRU evict', evict);
        _cache.remove(evict);
        _life.remove(evict);
      }
      _cache[key] = {};
      _life[key] = _initialLife;
    }
    _keys.remove(key);
    _keys.add(key);
    _cache[key]![page] = data;
  }

  /// 移除整个搜索条件的缓存
  static void remove(String key) {
    _cache.remove(key);
    _keys.remove(key);
    _life.remove(key);
  }

  /// 校验首页新鲜度: 对比缓存中第 1 页的 total + 整页漫画 uid/updated_at 序列
  ///
  /// 返回 true 表示缓存仍有效，调用方应复用已有缓存页。
  /// 返回 false 表示数据已变，调用方应清除旧缓存并重新缓存。
  static bool validateFreshness(String key, SearchResponse fresh) {
    final cached = get(key, 1);
    if (cached == null) return false;
    final cDocs = cached.comics.docs;
    final fDocs = fresh.comics.docs;
    if (cached.comics.total != fresh.comics.total) return false;
    if (cDocs.length != fDocs.length) return false;
    for (var i = 0; i < cDocs.length; i++) {
      if (cDocs[i].uid != fDocs[i].uid ||
          cDocs[i].updated_at != fDocs[i].updated_at) return false;
    }
    Log.i('Cache freshness passed',
        'total=${cached.comics.total} items=${cDocs.length}');
    return true;
  }

  /// 清空全部缓存
  static void clear() {
    Log.i('Cache cleared', '${_cache.length} entries');
    _cache.clear();
    _keys.clear();
    _life.clear();
  }
}
