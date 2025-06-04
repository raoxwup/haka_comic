import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// 用于commit前，更新 pubspec.yaml 和 setup_config.dart 版本.
void main(List<String> arguments) async {
  print('\x1B[36m\n🐦 Flutter Version Helper\x1B[0m');

  // 检查是否在 Git 仓库中
  if (!Directory('.git').existsSync()) {
    print('\x1B[31m❌ Not in a Git repository\x1B[0m');
    exit(1);
  }

  // 检查 pubspec.yaml 是否存在
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('\x1B[31m❌ pubspec.yaml not found\x1B[0m');
    exit(1);
  }

  // 读取当前版本
  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspec = loadYaml(pubspecContent) as YamlMap;
  final currentVersion = pubspec['version']?.toString() ?? '0.0.0';

  print('Current version: \x1B[33m$currentVersion\x1B[0m');

  // 询问是否需要更新
  stdout.write('\nUpdate version before commit? (y/N): ');
  final response = stdin.readLineSync()?.trim().toLowerCase();

  if (response != 'y' && response != 'yes') {
    print('\x1B[90mSkipping version update\x1B[0m');
    return;
  }

  String? newVersion;
  while (newVersion == null) {
    stdout.write(
      '\nEnter new version (format: x.x.x or x.x.x-beta.x): \x1B[32m',
    );
    final input = stdin.readLineSync()?.trim();
    stdout.write('\x1B[0m');

    if (input == null || input.isEmpty) {
      continue;
    }

    if (!RegExp(r'^\d+\.\d+\.\d+(-\w+\.\d+)?$').hasMatch(input)) {
      print(
        '\x1B[31mInvalid format. Use x.x.x or x.x.x-beta.x (e.g. 1.2.3 or 1.2.3-beta.4)\x1B[0m',
      );
    } else {
      newVersion = input;
    }
  }

  // 更新 pubspec.yaml
  updatePubspecVersion(newVersion);

  // 更新 setup_config.dart
  updateSetupConfigVersion(newVersion);

  print('\x1B[32m✓ Updated to version $newVersion in all files\x1B[0m');

  // 添加到 Git 暂存区
  final addResult = await Process.run('git', [
    'add',
    'pubspec.yaml',
    'lib/config/setup_config.dart',
  ]);
  if (addResult.exitCode != 0) {
    print('\x1B[31m❌ Failed to add files to git: ${addResult.stderr}\x1B[0m');
    exit(1);
  }

  print('\x1B[32m✓ Added updated files to git staging\x1B[0m');
}

// 更新 pubspec.yaml 版本
void updatePubspecVersion(String newVersion) {
  final pubspecFile = File('pubspec.yaml');
  final content = pubspecFile.readAsStringSync();
  final editor = YamlEditor(content);

  editor.update(['version'], newVersion);
  pubspecFile.writeAsStringSync(editor.toString());

  print('\x1B[32m✓ Updated pubspec.yaml to version $newVersion\x1B[0m');
}

// 更新 setup_config.dart 中的 appVersion
void updateSetupConfigVersion(String newVersion) {
  final configFile = File('lib/config/setup_config.dart');
  if (!configFile.existsSync()) {
    print(
      '\x1B[33m⚠️ lib/config/setup_config.dart not found. Skipping update.\x1B[0m',
    );
    return;
  }

  final content = configFile.readAsStringSync();
  final pattern = RegExp(r'static String appVersion = "(.+?)";');
  final match = pattern.firstMatch(content);

  if (match == null) {
    print(
      '\x1B[33m⚠️ Could not find appVersion in setup_config.dart. Skipping update.\x1B[0m',
    );
    return;
  }

  final newContent = content.replaceAll(
    match.group(0)!,
    'static String appVersion = "$newVersion";',
  );

  configFile.writeAsStringSync(newContent);
  print('\x1B[32m✓ Updated setup_config.dart to version $newVersion\x1B[0m');
}
