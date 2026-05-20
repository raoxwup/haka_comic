import 'package:haka_comic/network/models.dart';

/// 搜索结果 API 级多页 LRU 缓存（static 跨会话保留）
///
/// 外层键: normalizedKeyword|sort|categories（不含 page）
/// 内层键: page → SearchResponse
/// 淘汰策略: LRU，按搜索条件粒度淘汰
/// 失效策略: 首页新鲜度校验 + 连续两次无匹配清空全部
class SearchCache {
  static const int _maxSize = 200;
  static final Map<String, Map<int, SearchResponse>> _cache = {};
  static final List<String> _keys = [];
  static int _consecutiveMisses = 0;

  /// 构建缓存外层键（不含 page）
  static String buildKey(
    String normalizedKeyword,
    ComicSortType sort,
    List<String> categories,
  ) {
    return '$normalizedKeyword|${sort.name}|${categories.join(',')}';
  }

  /// 获取指定页的缓存数据
  static SearchResponse? get(String key, int page) {
    return _cache[key]?[page];
  }

  /// 获取某搜索条件下已缓存的页码列表
  static List<int> getCachedPages(String key) {
    return _cache[key]?.keys.toList() ?? [];
  }

  /// 写入缓存（LRU 顺序维护）
  static void put(String key, int page, SearchResponse data) {
    if (!_cache.containsKey(key)) {
      if (_cache.length >= _maxSize) {
        _cache.remove(_keys.removeAt(0));
      }
      _cache[key] = {};
    }
    _keys.remove(key);
    _keys.add(key);
    _cache[key]![page] = data;
  }

  /// 移除整个搜索条件的缓存
  static void remove(String key) {
    _cache.remove(key);
    _keys.remove(key);
  }

  /// 校验首页新鲜度: 对比缓存中第 1 页的 total 和首条漫画 ID
  ///
  /// 返回 true 表示缓存仍有效，调用方应复用已有缓存页。
  /// 返回 false 表示数据已变，调用方应清除旧缓存并重新缓存。
  static bool validateFreshness(String key, SearchResponse fresh) {
    final cachedPage1 = get(key, 1);
    if (cachedPage1 == null) return false;
    return cachedPage1.comics.total == fresh.comics.total &&
        _firstId(cachedPage1) == _firstId(fresh);
  }

  /// 记录一次缓存命中，重置连续未命中计数
  static void markHit() {
    _consecutiveMisses = 0;
  }

  /// 记录一次缓存未命中（新鲜度校验失败），递增连续未命中计数
  static void markMiss() {
    _consecutiveMisses++;
  }

  /// 连续两次搜索无匹配缓存时清空全部，返回是否执行了清空
  static bool checkAndClearStale() {
    if (_consecutiveMisses >= 2) {
      _cache.clear();
      _keys.clear();
      _consecutiveMisses = 0;
      return true;
    }
    return false;
  }

  /// 清空全部缓存
  static void clear() {
    _cache.clear();
    _keys.clear();
    _consecutiveMisses = 0;
  }

  /// 取 SearchResponse 中第一条漫画的 ID（用于新鲜度对比）
  static String? _firstId(SearchResponse r) {
    return r.comics.docs.isNotEmpty ? r.comics.docs.first.uid : null;
  }
}
