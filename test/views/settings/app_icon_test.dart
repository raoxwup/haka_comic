import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/views/settings/app_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('haka_comic/app_icon');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getIcon':
              return 'default';
            case 'setIcon':
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
}
