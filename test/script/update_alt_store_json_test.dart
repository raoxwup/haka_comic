import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String repoRoot;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('altstore_source_test_');
    repoRoot = Directory.current.path;
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'inserts a version plus build at index zero and keeps source metadata',
    () async {
      final sourcePath = '${tempDir.path}${Platform.pathSeparator}source.json';
      File(sourcePath).writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'name': 'Existing Source',
          'apps': <dynamic>[
            <String, dynamic>{
              'name': 'Existing App',
              'bundleIdentifier': 'com.github.raoxwup.hakacomic',
              'developerName': 'raoxwup',
              'versions': <dynamic>[
                <String, dynamic>{
                  'version': '1.2.0',
                  'buildVersion': '120',
                  'date': '2026-04-08T03:45:00Z',
                  'downloadURL': 'https://example.com/old.ipa',
                  'size': 100,
                  'minOSVersion': '13.0',
                },
              ],
            },
          ],
          'news': <dynamic>[],
        }),
      );

      final result = await Process.run(_dartExecutable(), <String>[
        'run',
        'script/update_alt_store_json.dart',
        '--json',
        sourcePath,
        '--version',
        '1.2.4+57',
        '--date',
        '2026-05-12T01:02:03Z',
        '--downloadURL',
        'https://github.com/raoxwup/haka_comic/releases/download/v1.2.4%2B57/no-codesign-ios-v1.2.4.ipa',
        '--size',
        '123456',
      ], workingDirectory: repoRoot);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final source =
          jsonDecode(File(sourcePath).readAsStringSync())
              as Map<String, dynamic>;
      expect(source['name'], 'Existing Source');
      expect(source['featuredApps'], contains('com.github.raoxwup.hakacomic'));

      final app = (source['apps'] as List).single as Map<String, dynamic>;
      expect(app['category'], 'entertainment');
      expect(app['tintColor'], '#F54F32');

      final versions = app['versions'] as List;
      expect(versions, hasLength(2));
      expect(versions.first, containsPair('version', '1.2.4'));
      expect(versions.first, containsPair('buildVersion', '57'));
      expect(versions.first, containsPair('size', 123456));
    },
  );

  test(
    'removes duplicate version and duplicate download URL entries',
    () async {
      final sourcePath = '${tempDir.path}${Platform.pathSeparator}source.json';
      File(sourcePath).writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'apps': <dynamic>[
            <String, dynamic>{
              'bundleIdentifier': 'com.github.raoxwup.hakacomic',
              'versions': <dynamic>[
                <String, dynamic>{
                  'version': '1.2.4',
                  'buildVersion': '57',
                  'date': '2026-05-01T00:00:00Z',
                  'downloadURL': 'https://example.com/same-version.ipa',
                  'size': 10,
                },
                <String, dynamic>{
                  'version': '1.2.3',
                  'buildVersion': '56',
                  'date': '2026-04-01T00:00:00Z',
                  'downloadURL': 'https://example.com/new.ipa',
                  'size': 10,
                },
              ],
            },
          ],
        }),
      );

      final result = await Process.run(_dartExecutable(), <String>[
        'run',
        'script/update_alt_store_json.dart',
        '--json',
        sourcePath,
        '--version',
        '1.2.4',
        '--buildVersion',
        '57',
        '--date',
        '2026-05-12T01:02:03Z',
        '--downloadURL',
        'https://example.com/new.ipa',
        '--size',
        '123456',
      ], workingDirectory: repoRoot);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final source =
          jsonDecode(File(sourcePath).readAsStringSync())
              as Map<String, dynamic>;
      final app = (source['apps'] as List).single as Map<String, dynamic>;
      final versions = app['versions'] as List;

      expect(versions, hasLength(1));
      expect(
        versions.single,
        containsPair('downloadURL', 'https://example.com/new.ipa'),
      );
    },
  );
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    return _dartFromFlutterRoot(flutterRoot);
  }

  final executable = File(Platform.resolvedExecutable).absolute.path;
  final normalized = executable.replaceAll(r'\', '/');
  final cacheIndex = normalized.indexOf('/bin/cache/');
  if (cacheIndex != -1) {
    final root = executable.substring(0, cacheIndex);
    return _dartFromFlutterRoot(root);
  }

  return Platform.isWindows ? 'dart.bat' : 'dart';
}

String _dartFromFlutterRoot(String flutterRoot) {
  return [
    flutterRoot,
    'bin',
    'cache',
    'dart-sdk',
    'bin',
    Platform.isWindows ? 'dart.exe' : 'dart',
  ].join(Platform.pathSeparator);
}
