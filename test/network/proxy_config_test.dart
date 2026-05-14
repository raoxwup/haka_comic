import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/network/proxy_config.dart';

void main() {
  group('ProxyConfig', () {
    test('round trips a SOCKS5 config through isolate payloads', () {
      const config = ProxyConfig.socks5(
        host: '127.0.0.1',
        port: 1080,
        username: 'user',
        password: 'pass',
      );

      expect(ProxyConfig.fromPayload(config.toPayload()), config);
    });

    test('treats missing payload values as direct mode', () {
      expect(
        ProxyConfig.fromPayload(const <String, dynamic>{}),
        ProxyConfig.direct,
      );
    });
  });
}
