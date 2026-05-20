class Cache {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _timestamps = {};

  /// 默认缓存 TTL：1 小时
  static const Duration defaultTtl = Duration(hours: 1);

  static void add(String key, Map<String, dynamic> map, {Duration? ttl}) {
    _cache[key] = map;
    _timestamps[key] = DateTime.now().add(ttl ?? defaultTtl);
  }

  static Map<String, dynamic>? get(String key) {
    final expiry = _timestamps[key];
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }
    return _cache[key];
  }

  static void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}
