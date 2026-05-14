import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/network/proxy_config.dart';
import 'package:haka_comic/network/proxy_controller.dart';

void main() {
  group('ProxyController', () {
    test('start applies the saved manual proxy config without polling', () {
      const savedProxy = ProxyConfig.socks5(host: '127.0.0.1', port: 1080);
      final applied = <ProxyConfig>[];

      final controller = ProxyController(
        loadProxy: () => savedProxy,
        saveProxy: (_) {},
        applyProxy: applied.add,
      );

      controller.start();

      expect(controller.currentProxy, savedProxy);
      expect(applied, [savedProxy]);
    });

    test(
      'update saves, applies, and notifies only when the config changes',
      () {
        final saved = <ProxyConfig>[];
        final applied = <ProxyConfig>[];
        final notified = <ProxyConfig>[];
        const socksProxy = ProxyConfig.socks5(host: '127.0.0.1', port: 7891);

        final controller = ProxyController(
          loadProxy: () => ProxyConfig.direct,
          saveProxy: saved.add,
          applyProxy: applied.add,
        )..addListener(notified.add);

        controller.start();
        controller.update(socksProxy);
        controller.update(socksProxy);

        expect(saved, [socksProxy]);
        expect(applied, [ProxyConfig.direct, socksProxy]);
        expect(notified, [ProxyConfig.direct, socksProxy]);
        expect(controller.currentProxy, socksProxy);
      },
    );
  });
}
