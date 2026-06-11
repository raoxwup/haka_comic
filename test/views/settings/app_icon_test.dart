import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/views/settings/app_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const packageName = 'com.github.raoxwup.haka_comic';
  const channel = MethodChannel('flutter_dynamic_icon_plus');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getAlternateIconName':
              return '$packageName.IconClassic';
            case 'supportsAlternateIcons':
              return true;
            case 'setAlternateIconName':
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('app icon selector uses preview cards instead of radio rows', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppIcon())));
    await tester.pump();

    await tester.tap(find.text('应用图标'));
    await tester.pumpAndSettle();

    expect(find.text('选择应用图标'), findsOneWidget);
    expect(find.text('选择后将应用新的应用图标'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(
      tester.widgetList<Image>(find.byType(Image)).map((image) => image.width),
      everyElement(72),
    );
    expect(find.byType(RadioListTile<String>), findsNothing);
  });

  testWidgets('selecting an icon passes the Android alias to the plugin', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppIcon())));
    await tester.pump();

    await tester.tap(find.text('应用图标'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('现代'));
    await tester.pumpAndSettle();

    final setIconCall = calls.singleWhere(
      (call) => call.method == 'setAlternateIconName',
    );
    expect(
      setIconCall.arguments,
      containsPair('iconName', '$packageName.IconModern'),
    );
  });
}
