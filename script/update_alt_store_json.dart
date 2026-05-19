import 'dart:convert';
import 'dart:io';

const _defaultBundleId = 'com.github.raoxwup.hakacomic';
const _defaultMinOSVersion = '13.0';
const _defaultIconURL =
    'https://raw.githubusercontent.com/raoxwup/haka_comic/main/assets/icons/ios/AppIcon.png';
const _defaultTintColor = '#F54F32';

const _sourceDefaults = <String, dynamic>{
  'name': 'HaKa Comic',
  'subtitle': '第三方哗咔漫画跨平台客户端',
  'description': '用于通过 AltStore / SideStore 安装与更新 HaKa Comic（iOS IPA）。',
  'website': 'https://github.com/raoxwup/haka_comic',
  'iconURL': _defaultIconURL,
  'tintColor': _defaultTintColor,
};

const _appDefaults = <String, dynamic>{
  'name': 'HaKa Comic',
  'developerName': 'raoxwup',
  'subtitle': '第三方哗咔漫画客户端',
  'localizedDescription': '第三方哗咔漫画跨平台客户端（学习/练习项目）。',
  'iconURL': _defaultIconURL,
  'tintColor': _defaultTintColor,
  'category': 'entertainment',
};

const _privacyPermissions = <String, String>{
  'NSAppleMusicUsageDescription': 'Allow Runner to access your music.',
  'NSFaceIDUsageDescription': 'Biometric authentication is required.',
  'NSPhotoLibraryUsageDescription': 'Allow Runner to access your photos.',
};

void main(List<String> args) {
  try {
    _run(args);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}

void _run(List<String> args) {
  final parsed = _parseArgs(args);
  final jsonPath = parsed['json'] ?? 'alt_store.json';
  final ipaPath = parsed['ipa'];
  final sizeArg = parsed['size'];
  final resolvedVersion = _resolveVersion(
    parsed['version'],
    parsed['buildVersion'],
  );
  final date = parsed['date'] ?? _utcIso8601NoMillis(DateTime.now().toUtc());
  final minOSVersion = parsed['minOSVersion'] ?? _defaultMinOSVersion;

  final bundleId = parsed['bundleIdentifier'] ?? _defaultBundleId;
  final downloadURL =
      parsed['downloadURL'] ??
      _buildDownloadUrl(parsed, resolvedVersion.version);
  final keep = int.tryParse(parsed['keep'] ?? '') ?? 5;

  if (downloadURL == null || downloadURL.isEmpty) {
    throw const FormatException(
      'Missing download url. Provide --downloadURL, or provide --repo and --tag.',
    );
  }
  if (!_hasHttpScheme(downloadURL)) {
    throw FormatException('Invalid download URL: $downloadURL');
  }
  if (DateTime.tryParse(date) == null) {
    throw FormatException('Invalid ISO 8601 date: $date');
  }

  final size = _resolveSize(sizeArg, ipaPath);
  if (size == null) {
    throw const FormatException(
      'Missing size. Provide --size <bytes>, or --ipa <path-to-ipa>.',
    );
  }

  final root = _loadOrCreateSource(File(jsonPath));
  _normalizeSource(root, bundleId);
  final app = _findOrCreateApp(root, bundleId);
  _normalizeApp(app, bundleId);

  final versions = _versionList(app['versions']);

  // Remove duplicates (same version+buildVersion, or same downloadURL).
  versions.removeWhere((v) {
    final vVersion = v['version']?.toString();
    final vBuild = v['buildVersion']?.toString();
    final vUrl = v['downloadURL']?.toString();
    return (vVersion == resolvedVersion.version &&
            vBuild == resolvedVersion.buildVersion) ||
        vUrl == downloadURL;
  });

  versions.insert(0, <String, dynamic>{
    'version': resolvedVersion.version,
    'buildVersion': resolvedVersion.buildVersion,
    'date': date,
    'downloadURL': downloadURL,
    'size': size,
    'minOSVersion': minOSVersion,
  });

  if (keep > 0 && versions.length > keep) {
    versions.removeRange(keep, versions.length);
  }

  app['versions'] = versions;

  final encoder = const JsonEncoder.withIndent('  ');
  File(jsonPath).writeAsStringSync('${encoder.convert(root)}\n');
  stdout.writeln(
    'Updated $jsonPath: version=${resolvedVersion.version} '
    'buildVersion=${resolvedVersion.buildVersion} size=$size',
  );
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) continue;

    final eq = a.indexOf('=');
    if (eq != -1) {
      out[a.substring(2, eq)] = a.substring(eq + 1);
      continue;
    }

    // Support: --key value
    if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      out[a.substring(2)] = args[i + 1];
      i++;
      continue;
    }

    // Support boolean flag style: --foo (treated as "true")
    out[a.substring(2)] = 'true';
  }
  return out;
}

int? _resolveSize(String? sizeArg, String? ipaPath) {
  if (sizeArg != null && sizeArg.trim().isNotEmpty) {
    final size = int.tryParse(sizeArg.trim());
    return size != null && size > 0 ? size : null;
  }

  if (ipaPath == null || ipaPath.isEmpty) return null;
  final ipaFile = File(ipaPath);
  if (!ipaFile.existsSync()) return null;
  final size = ipaFile.lengthSync();
  return size > 0 ? size : null;
}

String _utcIso8601NoMillis(DateTime utc) {
  final iso = utc.toIso8601String();
  // 2026-02-23T10:44:52.123Z -> 2026-02-23T10:44:52Z
  final noMillis = iso.split('.').first;
  return '${noMillis}Z';
}

String? _buildDownloadUrl(Map<String, String> parsed, String? version) {
  if (version == null || version.isEmpty) return null;
  final repo = parsed['repo'] ?? Platform.environment['GITHUB_REPOSITORY'];
  final tag = parsed['tag'];
  final assetName = parsed['assetName'] ?? 'no-codesign-ios-v$version.ipa';
  if (repo == null || repo.isEmpty || tag == null || tag.isEmpty) return null;
  return 'https://github.com/$repo/releases/download/$tag/$assetName';
}

Map<String, dynamic> _loadOrCreateSource(File file) {
  if (file.existsSync()) {
    final raw = file.readAsStringSync();
    if (raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('Source JSON root must be an object.');
    }
  }

  return <String, dynamic>{
    ..._sourceDefaults,
    'featuredApps': <String>[_defaultBundleId],
    'apps': <dynamic>[],
    'news': <dynamic>[],
  };
}

Map<String, dynamic> _findOrCreateApp(
  Map<String, dynamic> root,
  String bundleId,
) {
  final apps = root['apps'];
  if (apps is! List) {
    throw const FormatException('Source JSON "apps" must be an array.');
  }

  for (final item in apps) {
    if (item is Map<String, dynamic> &&
        item['bundleIdentifier']?.toString() == bundleId) {
      return item;
    }
    if (item is Map && item['bundleIdentifier']?.toString() == bundleId) {
      final app = Map<String, dynamic>.from(item);
      final index = apps.indexOf(item);
      apps[index] = app;
      return app;
    }
  }

  final created = <String, dynamic>{
    ..._appDefaults,
    'bundleIdentifier': bundleId,
    'versions': <dynamic>[],
  };

  apps.add(created);
  return created;
}

void _normalizeSource(Map<String, dynamic> root, String bundleId) {
  for (final entry in _sourceDefaults.entries) {
    root.putIfAbsent(entry.key, () => entry.value);
  }

  final apps = root['apps'];
  if (apps == null) {
    root['apps'] = <dynamic>[];
  } else if (apps is! List) {
    throw const FormatException('Source JSON "apps" must be an array.');
  }

  final news = root['news'];
  if (news == null) {
    root['news'] = <dynamic>[];
  } else if (news is! List) {
    throw const FormatException('Source JSON "news" must be an array.');
  }

  final featuredApps = root['featuredApps'];
  if (featuredApps is List) {
    final normalized = featuredApps.map((item) => item.toString()).toList();
    if (!normalized.contains(bundleId)) {
      normalized.insert(0, bundleId);
    }
    root['featuredApps'] = normalized;
  } else {
    root['featuredApps'] = <String>[bundleId];
  }
}

void _normalizeApp(Map<String, dynamic> app, String bundleId) {
  for (final entry in _appDefaults.entries) {
    app.putIfAbsent(entry.key, () => entry.value);
  }
  app['bundleIdentifier'] = bundleId;

  final permissions = app['appPermissions'];
  final normalizedPermissions = permissions is Map
      ? Map<String, dynamic>.from(permissions)
      : <String, dynamic>{};
  final entitlements = normalizedPermissions['entitlements'];
  normalizedPermissions['entitlements'] = entitlements is List
      ? entitlements.map((item) => item.toString()).toList()
      : <String>[];
  normalizedPermissions['privacy'] = <String, String>{..._privacyPermissions};
  app['appPermissions'] = normalizedPermissions;

  final versions = app['versions'];
  if (versions == null) {
    app['versions'] = <dynamic>[];
  } else if (versions is! List) {
    throw const FormatException('App JSON "versions" must be an array.');
  }
}

List<Map<String, dynamic>> _versionList(Object? value) {
  if (value == null) return <Map<String, dynamic>>[];
  if (value is! List) {
    throw const FormatException('App JSON "versions" must be an array.');
  }

  return value.map((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    throw const FormatException('Each app version must be an object.');
  }).toList();
}

_ResolvedVersion _resolveVersion(String? versionArg, String? buildVersionArg) {
  final rawVersion = versionArg?.trim();
  if (rawVersion == null || rawVersion.isEmpty) {
    throw const FormatException(
      'Missing required arg: --version <app-version>',
    );
  }

  final explicitBuild = buildVersionArg?.trim();
  if (explicitBuild != null && explicitBuild.isNotEmpty) {
    return _ResolvedVersion(rawVersion, explicitBuild);
  }

  final plusIndex = rawVersion.indexOf('+');
  if (plusIndex == -1) {
    return _ResolvedVersion(rawVersion, rawVersion);
  }

  final version = rawVersion.substring(0, plusIndex).trim();
  final buildVersion = rawVersion.substring(plusIndex + 1).trim();
  if (version.isEmpty || buildVersion.isEmpty) {
    throw FormatException('Invalid version/build value: $rawVersion');
  }
  return _ResolvedVersion(version, buildVersion);
}

bool _hasHttpScheme(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
}

class _ResolvedVersion {
  const _ResolvedVersion(this.version, this.buildVersion);

  final String version;
  final String buildVersion;
}
