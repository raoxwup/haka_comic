import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/network/proxy_config.dart';
import 'package:haka_comic/network/proxy_controller.dart';
import 'package:haka_comic/views/settings/proxy_settings.dart';

void main() {
  testWidgets('enables SOCKS5 only after required fields are valid', (
    tester,
  ) async {
    final saved = <ProxyConfig>[];
    final applied = <ProxyConfig>[];
    final controller = ProxyController(
      loadProxy: () => ProxyConfig.direct,
      saveProxy: saved.add,
      applyProxy: applied.add,
    )..start();

    await tester.pumpWidget(
      MaterialApp(home: ProxySettings(controller: controller)),
    );

    expect(find.text('保存'), findsNothing);

    final hostField = find.widgetWithText(TextFormField, '主机');
    final portField = find.widgetWithText(TextFormField, '端口');
    final switchTile = find.byType(SwitchListTile);
    expect(
      tester.getTopLeft(switchTile).dy,
      greaterThan(tester.getTopLeft(portField).dy),
    );
    expect(
      tester.getTopLeft(switchTile).dy,
      greaterThan(
        tester.getTopLeft(find.textContaining('SOCKS5 会让代理服务器解析目标域名')).dy,
      ),
    );

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tester.enterText(hostField, '127.0.0.1');
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tester.enterText(portField, '1080');
    await tester.enterText(find.widgetWithText(TextFormField, '用户名'), 'user');
    await tester.enterText(find.widgetWithText(TextFormField, '密码'), 'pass');
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    expect(saved.last, _directWithSavedFields);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(saved.last, _socks5WithSavedFields);
    expect(applied.last, saved.last);
    expect(_fieldIsEnabled(tester, '主机'), isFalse);
    expect(_fieldIsEnabled(tester, '端口'), isFalse);
    expect(_fieldIsEnabled(tester, '用户名'), isFalse);
    expect(_fieldIsEnabled(tester, '密码'), isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(saved.last, _directWithSavedFields);
    expect(_fieldIsEnabled(tester, '主机'), isTrue);
    expect(_fieldIsEnabled(tester, '端口'), isTrue);
    expect(_fieldIsEnabled(tester, '用户名'), isTrue);
    expect(_fieldIsEnabled(tester, '密码'), isTrue);
  });

  testWidgets('keeps manual proxy fields when proxy is disabled', (
    tester,
  ) async {
    final controller = ProxyController(
      loadProxy: () => _directWithSavedFields,
      saveProxy: (_) {},
      applyProxy: (_) {},
    )..start();

    await tester.pumpWidget(
      MaterialApp(home: ProxySettings(controller: controller)),
    );

    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, '主机'))
          .controller
          ?.text,
      '127.0.0.1',
    );
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, '端口'))
          .controller
          ?.text,
      '1080',
    );
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, '用户名'))
          .controller
          ?.text,
      'user',
    );
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, '密码'))
          .controller
          ?.text,
      'pass',
    );
  });
}

const _directWithSavedFields = ProxyConfig.directWith(
  host: '127.0.0.1',
  port: 1080,
  username: 'user',
  password: 'pass',
);

const _socks5WithSavedFields = ProxyConfig.socks5(
  host: '127.0.0.1',
  port: 1080,
  username: 'user',
  password: 'pass',
);

bool _fieldIsEnabled(WidgetTester tester, String label) {
  return tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, label))
      .enabled;
}
