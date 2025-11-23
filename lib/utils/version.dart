class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;
  final List<Object> preRelease;

  Version({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease = const [],
  });

  factory Version.parse(String versionStr) {
    final regex = RegExp(
      r'^v?(\d+)\.(\d+)\.(\d+)(?:-([\w\.]+))?',
      caseSensitive: false,
    );

    final match = regex.firstMatch(versionStr);
    if (match == null) throw FormatException('Invalid version: $versionStr');

    final preRelease = (match.group(4) ?? '')
        .split('.')
        .where((s) => s.isNotEmpty)
        .map<Object>((s) => int.tryParse(s) ?? s)
        .toList();

    return Version(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      preRelease: preRelease,
    );
  }

  @override
  int compareTo(Version other) {
    // 比较主版本号
    if (major != other.major) return major.compareTo(other.major);

    // 比较次版本号
    if (minor != other.minor) return minor.compareTo(other.minor);

    // 比较修订号
    if (patch != other.patch) return patch.compareTo(other.patch);

    // 处理预发布标签比较
    return _comparePreRelease(other.preRelease);
  }

  int _comparePreRelease(List<Object> other) {
    final a = preRelease;
    final b = other;

    // 正式版本 > 预发布版本
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;

    for (var i = 0; i < a.length && i < b.length; i++) {
      final itemA = a[i];
      final itemB = b[i];

      // 类型不同时：数字 < 字符串
      if (itemA is num && itemB is! num) return -1;
      if (itemA is! num && itemB is num) return 1;

      // 同类型比较
      final comparison = _compareItems(itemA, itemB);
      if (comparison != 0) return comparison;
    }

    // 长度不同时：标识符更多的一方更大
    return a.length.compareTo(b.length);
  }

  int _compareItems(Object a, Object b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    } else if (a is String && b is String) {
      return a.compareTo(b);
    }
    return 0;
  }

  @override
  String toString() {
    final version = '$major.$minor.$patch';
    if (preRelease.isEmpty) return version;
    return '$version-${preRelease.join('.')}';
  }
}
