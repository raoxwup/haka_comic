import 'dart:convert';
import 'dart:io';

const _defaultBundleId = 'com.github.raoxwup.hakacomic';

void main(List<String> args) async {
  final parsed = _parseArgs(args);

  final jsonPath = parsed['json'] ?? 'alt_store.json';
  final ipaPath = parsed['ipa'];
  final sizeArg = parsed['size'];
  final version = parsed['version'];
  final buildVersion = parsed['buildVersion'] ?? version;
  final date = parsed['date'] ?? _utcIso8601NoMillis(DateTime.now().toUtc());
  final minOSVersion = parsed['minOSVersion'] ?? '13.0';

  final bundleId = parsed['bundleIdentifier'] ?? _defaultBundleId;
  final downloadURL = parsed['downloadURL'] ?? _buildDownloadUrl(parsed, version);
  final keep = int.tryParse(parsed['keep'] ?? '') ?? 5;

  if (version == null || version.isEmpty) {
    stderr.writeln('Missing required arg: --version <app-version>');
    exitCode = 2;
    return;
  }
  if (downloadURL == null || downloadURL.isEmpty) {
    stderr.writeln(
      'Missing download url. Provide --downloadURL, or provide --repo and --tag.',
    );
    exitCode = 2;
    return;
  }

  final size = _resolveSize(sizeArg, ipaPath);
  if (size == null) {
    stderr.writeln('Missing size. Provide --size <bytes>, or --ipa <path-to-ipa>.');
    exitCode = 2;
    return;
  }

  final root = _loadOrCreateSource(File(jsonPath));
  final app = _findOrCreateApp(root, bundleId);

  final versions = (app['versions'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

  // Remove duplicates (same version+buildVersion, or same downloadURL).
  versions.removeWhere((v) {
    final vVersion = v['version']?.toString();
    final vBuild = v['buildVersion']?.toString();
    final vUrl = v['downloadURL']?.toString();
    return (vVersion == version && vBuild == buildVersion) || (vUrl == downloadURL);
  });

  versions.insert(0, <String, dynamic>{
    'version': version,
    'buildVersion': buildVersion,
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
  stdout.writeln('Updated $jsonPath: version=$version buildVersion=$buildVersion size=$size');
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
    return int.tryParse(sizeArg.trim());
  }

  if (ipaPath == null || ipaPath.isEmpty) return null;
  final ipaFile = File(ipaPath);
  if (!ipaFile.existsSync()) return null;
  return ipaFile.lengthSync();
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
    }
  }

  // Minimal skeleton that matches AltStore/SideStore source format.
  return <String, dynamic>{
    'name': 'HaKa Comic',
    'subtitle': '第三方哗咔漫画跨平台客户端',
    'description': '用于通过 AltStore / SideStore 安装与更新 HaKa Comic（iOS IPA）。',
    'website': 'https://github.com/raoxwup/haka_comic',
    'iconURL': 'https://raw.githubusercontent.com/raoxwup/haka_comic/main/assets/icons/ios/Light.png',
    'apps': <dynamic>[],
    'news': <dynamic>[],
  };
}

Map<String, dynamic> _findOrCreateApp(Map<String, dynamic> root, String bundleId) {
  final apps = (root['apps'] as List?) ?? <dynamic>[];

  for (final item in apps) {
    if (item is Map<String, dynamic> && item['bundleIdentifier']?.toString() == bundleId) {
      return item;
    }
  }

  final created = <String, dynamic>{
    'name': 'HaKa Comic',
    'bundleIdentifier': bundleId,
    'developerName': 'raoxwup',
    'subtitle': '第三方哗咔漫画客户端',
    'localizedDescription': '第三方哗咔漫画跨平台客户端（学习/练习项目）。',
    'iconURL': 'https://raw.githubusercontent.com/raoxwup/haka_comic/main/assets/icons/ios/Light.png',
    'versions': <dynamic>[],
  };

  apps.add(created);
  root['apps'] = apps;
  return created;
}
