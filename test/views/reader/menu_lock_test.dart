import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/reader.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/views/reader/widgets/horizontal_list/horizontal_list.dart';
import 'package:haka_comic/views/reader/widgets/menu_lock.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final chapter = Chapter(
    uid: 'chapter-uid',
    title: 'Chapter 1',
    order: 1,
    updated_at: '',
    id: 'chapter-id',
  );

  setUp(() async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({'menuLocked': false});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'menuLocked': false});
    SharedPreferencesUtil.prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );
    AppConf().menuLocked = false;
    AppConf().enableVolume = false;
  });

  ReaderProvider createReaderProvider() {
    return ReaderProvider(
      state: ComicState(
        id: 'comic-id',
        title: 'Comic',
        chapters: [chapter],
        chapter: chapter,
        pageNo: 0,
      ),
      fetchImages: (_) => Completer<List<ImageBase>>().future,
      saveReadRecord: (ComicReadRecord record) async {},
    );
  }

  Future<void> pumpMenuLock(
    WidgetTester tester, {
    required ReaderProvider readerProvider,
    required ListStateProvider listStateProvider,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReaderProvider>.value(value: readerProvider),
          ChangeNotifierProvider<ListStateProvider>.value(
            value: listStateProvider,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [MenuLock()])),
        ),
      ),
    );
  }

  Future<void> pumpReader(
    WidgetTester tester, {
    required ReaderProvider readerProvider,
    required ListStateProvider listStateProvider,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReaderProvider>.value(value: readerProvider),
          ChangeNotifierProvider<ListStateProvider>.value(
            value: listStateProvider,
          ),
        ],
        child: const MaterialApp(home: Reader()),
      ),
    );
  }

  void dispatchReaderScroll(WidgetTester tester, double scrollDelta) {
    final context = tester.element(find.byType(HorizontalList));
    ScrollUpdateNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        pixels: scrollDelta,
        viewportDimension: 100,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: context,
      scrollDelta: scrollDelta,
    ).dispatch(context);
  }

  double menuLockSurfaceAlpha(WidgetTester tester) {
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('menu_lock_button')),
        matching: find.byType(Material),
      ),
    );
    final color = material.color!;
    return ((color.toARGB32() >> 24) & 0xff) / 255.0;
  }

  testWidgets('follows toolbar visibility while the menu is unlocked', (
    tester,
  ) async {
    final readerProvider = createReaderProvider();
    final listStateProvider = ListStateProvider();

    await pumpMenuLock(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    expect(find.byKey(const ValueKey('menu_lock_button')), findsNothing);

    readerProvider.openOrCloseToolbar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('menu_lock_button')), findsOneWidget);
  });

  testWidgets('locked MenuLock stays expanded after outside tap', (
    tester,
  ) async {
    final readerProvider = createReaderProvider();
    AppConf().menuLocked = true;
    final listStateProvider = ListStateProvider();

    await pumpMenuLock(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    final button = find.byKey(const ValueKey('menu_lock_button'));
    expect(button, findsOneWidget);
    expect(find.byKey(const ValueKey('menu_lock_collapsed')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsNothing);
    expect(listStateProvider.lockMenu, isTrue);
    expect(readerProvider.showToolbar, isFalse);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_collapsed')), findsNothing);
    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsOneWidget);
    expect(listStateProvider.lockMenu, isTrue);
    expect(readerProvider.showToolbar, isFalse);

    await tester.tapAt(const Offset(700, 300));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_collapsed')), findsNothing);
    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsOneWidget);
  });

  testWidgets('expanded locked MenuLock collapses when the list scrolls', (
    tester,
  ) async {
    final readerProvider = createReaderProvider();
    AppConf().menuLocked = true;
    final listStateProvider = ListStateProvider();

    await pumpMenuLock(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    await tester.tap(find.byKey(const ValueKey('menu_lock_button')));
    await tester.pumpAndSettle();

    readerProvider.collapseMenuLock();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_collapsed')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsNothing);
  });

  testWidgets('locked MenuLock collapses only after scroll threshold', (
    tester,
  ) async {
    AppConf().menuLocked = true;
    AppConf().readMode = ReadMode.leftToRight;
    final readerProvider = createReaderProvider()
      ..handler.mutate([
        LocalImage(uid: 'page-1', id: 'page-1', url: 'page-1.jpg'),
        LocalImage(uid: 'page-2', id: 'page-2', url: 'page-2.jpg'),
      ]);
    final listStateProvider = ListStateProvider();

    await pumpReader(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    await tester.tap(find.byKey(const ValueKey('menu_lock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsOneWidget);

    dispatchReaderScroll(tester, 10);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsOneWidget);

    dispatchReaderScroll(tester, 20);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_collapsed')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsNothing);
  });

  testWidgets('collapsed locked MenuLock has lower surface opacity', (
    tester,
  ) async {
    final readerProvider = createReaderProvider();
    AppConf().menuLocked = true;
    final listStateProvider = ListStateProvider();

    await pumpMenuLock(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    expect(menuLockSurfaceAlpha(tester), closeTo(0.42, 0.01));

    await tester.tap(find.byKey(const ValueKey('menu_lock_button')));
    await tester.pumpAndSettle();

    expect(menuLockSurfaceAlpha(tester), closeTo(0.66, 0.01));
  });

  testWidgets('expanded locked MenuLock unlocks on the next tap', (
    tester,
  ) async {
    final readerProvider = createReaderProvider();
    AppConf().menuLocked = true;
    final listStateProvider = ListStateProvider();

    await pumpMenuLock(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    final button = find.byKey(const ValueKey('menu_lock_button'));
    await tester.tap(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pump();

    expect(listStateProvider.lockMenu, isFalse);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('expanded locked MenuLock stays expanded when focus is lost', (
    tester,
  ) async {
    final readerProvider = createReaderProvider();
    AppConf().menuLocked = true;
    final listStateProvider = ListStateProvider();

    await pumpMenuLock(
      tester,
      readerProvider: readerProvider,
      listStateProvider: listStateProvider,
    );

    final button = find.byKey(const ValueKey('menu_lock_button'));
    await tester.tap(button);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu_lock_collapsed')), findsNothing);
    expect(find.byKey(const ValueKey('menu_lock_expanded')), findsOneWidget);
  });
}
