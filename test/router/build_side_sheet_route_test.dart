import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/router/build_side_sheet_route.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/details'),
                child: const Text('open details'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/details',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/comments/1'),
                child: const Text('open comments'),
              ),
            ),
          ),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) {
            return buildSideSheetRoutePage(context, state, child);
          },
          routes: [
            GoRoute(
              path: '/comments/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => context.push('/comments/1/sub_comments'),
                    child: const Text('open sub comments'),
                  ),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'sub_comments',
                  builder: (context, state) =>
                      const Scaffold(body: Center(child: Text('sub comments'))),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  tearDown(() {
    router.dispose();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> openComments(WidgetTester tester) async {
    await tester.tap(find.text('open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open comments'));
    await tester.pumpAndSettle();
  }

  testWidgets('outside tap pops nested side sheet route first', (tester) async {
    await pumpRouter(tester);
    await openComments(tester);

    await tester.tap(find.text('open sub comments'));
    await tester.pumpAndSettle();

    expect(find.text('sub comments'), findsOneWidget);

    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();

    expect(find.text('open sub comments'), findsOneWidget);
    expect(find.text('sub comments'), findsNothing);
  });

  testWidgets('double outside tap only dismisses the side sheet once', (
    tester,
  ) async {
    await pumpRouter(tester);
    await openComments(tester);

    expect(find.text('open sub comments'), findsOneWidget);

    await tester.tapAt(const Offset(20, 100));
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();

    expect(find.text('open comments'), findsOneWidget);
    expect(find.text('open details'), findsNothing);
    expect(find.text('open sub comments'), findsNothing);
  });
}
