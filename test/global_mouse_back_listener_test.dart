import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/widgets/global_mouse_back_listener.dart';

void main() {
  Future<void> pumpTestApp(
    WidgetTester tester, {
    required GlobalKey<NavigatorState> navigatorKey,
    bool enabled = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/second',
        routes: {
          '/': (_) => const Scaffold(body: Center(child: Text('first'))),
          '/second': (_) => const Scaffold(body: Center(child: Text('second'))),
        },
        builder: (context, child) {
          return GlobalMouseBackListener(
            navigatorKey: navigatorKey,
            enabled: enabled,
            child: child!,
          );
        },
      ),
    );
  }

  testWidgets('鼠标后退侧键会触发返回', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpTestApp(tester, navigatorKey: navigatorKey);

    expect(find.text('second'), findsOneWidget);

    final center = tester.getCenter(find.byType(Scaffold).last);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kBackMouseButton,
    );
    await gesture.addPointer(location: center);
    await tester.pump();
    await gesture.down(center);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);
  });

  testWidgets('非后退键不会误触发返回', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpTestApp(tester, navigatorKey: navigatorKey);

    final center = tester.getCenter(find.byType(Scaffold).last);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await gesture.addPointer(location: center);
    await tester.pump();
    await gesture.down(center);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsNothing);
  });

  testWidgets('监听禁用时不会触发返回', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpTestApp(tester, navigatorKey: navigatorKey, enabled: false);

    final center = tester.getCenter(find.byType(Scaffold).last);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kBackMouseButton,
    );
    await gesture.addPointer(location: center);
    await tester.pump();
    await gesture.down(center);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsNothing);
  });
}
