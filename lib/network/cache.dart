class Cache {
  static final Map<String, Object> _cache = {};
  static final Map<String, DateTime> _timestamps = {};

  /// 默认缓存 TTL：1 小时
  static const Duration defaultTtl = Duration(hours: 1);

  /// 存入缓存，支持任意类型
  static void add<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = value as Object;
    _timestamps[key] = DateTime.now().add(ttl ?? defaultTtl);
  }

  /// 读取缓存，自动过期检查
  static T? get<T>(String key) {
    final expiry = _timestamps[key];
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }
    final value = _cache[key];
    if (value is T) return value;
    return null;
  }

  static void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}
