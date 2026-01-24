import 'dart:io';

import 'package:yaml/yaml.dart';

void main() async {
  var pubspec = await File("pubspec.yaml").readAsString();
  final data = loadYaml(pubspec);
  var config = await File("lib/config/setup_config.dart").readAsString();
  config = config.replaceFirst('#version', data['version']);
  await File("lib/config/setup_config.dart").writeAsString(config);
  print("Successfully patched version.");
}
