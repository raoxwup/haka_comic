class Cache {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static void add(String key, Map<String, dynamic> map) {
    _cache[key] = map;
  }

  static Map<String, dynamic>? get(String key) {
    return _cache[key];
  }

  static void clear() {
    _cache.clear();
  }
}
