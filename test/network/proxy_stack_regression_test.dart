import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('proxy stack implementation', () {
    test('uses socks5_proxy instead of the in-tree SOCKS5 connector', () {
      final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
      final dependencies = pubspec['dependencies'] as Map;
      expect(dependencies['socks5_proxy'], '^2.1.1');

      final overrides = File(
        'lib/network/proxy_overrides.dart',
      ).readAsStringSync();
      expect(overrides, contains("package:socks5_proxy/socks_client.dart"));
      expect(overrides, isNot(contains('Socks5Connector')));
      expect(File('lib/network/socks5_connector.dart').existsSync(), isFalse);
    });
  });
}
