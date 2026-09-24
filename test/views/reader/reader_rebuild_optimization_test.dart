import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/views/reader/widgets/bottom.dart';
import 'package:haka_comic/views/reader/widgets/next_chapter.dart';
import 'package:haka_comic/views/reader/widgets/reader_keyboard_listener.dart';
import 'package:haka_comic/views/reader/widgets/vertical_list/gesture.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final chapter = Chapter(
    uid: 'chapter-uid',
    title: 'Chapter 1',
    order: 1,
    updated_at: '',
    id: 'chapter-id',
  );
  final nextChapter = Chapter(
    uid: 'next-chapter-uid',
    title: 'Chapter 2',
    order: 2,
    updated_at: '',
    id: 'next-chapter-id',
  );

  ReaderProvider createReaderProvider() {
    return ReaderProvider(
        state: ComicState(
          id: 'comic-id',
          title: 'Comic',
          chapters: [chapter, nextChapter],
          chapter: chapter,
          pageNo: 0,
        ),
        fetchImages: (_) => Completer<List<ImageBase>>().future,
        saveReadRecord: (ComicReadRecord record) async {},
      )
      ..handler.mutate([
        LocalImage(uid: 'page-1', id: 'page-1', url: 'page-1.jpg'),
        LocalImage(uid: 'page-2', id: 'page-2', url: 'page-2.jpg'),
        LocalImage(uid: 'page-3', id: 'page-3', url: 'page-3.jpg'),
        LocalImage(uid: 'page-4', id: 'page-4', url: 'page-4.jpg'),
      ]);
  }

  Widget withReaderProviders({
    required ReaderProvider reader,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ReaderProvider>.value(value: reader),
        ChangeNotifierProvider<ListStateProvider>.value(
          value: ListStateProvider(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: Stack(children: [child])),
      ),
    );
  }

  testWidgets('does not mount PageSlider while the toolbar is hidden', (
    tester,
  ) async {
    final reader = createReaderProvider();

    await tester.pumpWidget(
      withReaderProviders(reader: reader, child: const ReaderBottom()),
    );

    expect(find.byType(PageSlider), findsNothing);
  });

  testWidgets(
    'does not rebuild ReaderNextChapter when page changes without changing visibility',
    (tester) async {
      final reader = createReaderProvider();

      await tester.pumpWidget(
        withReaderProviders(reader: reader, child: const ReaderNextChapter()),
      );

      var rebuilds = 0;
      final previousCallback = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element.widget is ReaderNextChapter) {
          rebuilds++;
        }
        previousCallback?.call(element, builtOnce);
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previousCallback);

      reader.pageNo = 1;
      await tester.pump();

      expect(rebuilds, 0);
    },
  );

  testWidgets('desktop single pointer changes do not rebuild GestureWrapper', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ListStateProvider>.value(
        value: ListStateProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: GestureWrapper(
              openOrCloseToolbar: () {},
              jumpOffset: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    var rebuilds = 0;
    final previousCallback = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is GestureWrapper) {
        rebuilds++;
      }
      previousCallback?.call(element, builtOnce);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previousCallback);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GestureWrapper)),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(rebuilds, 0);
  });

  test('ReaderKeyboardListener owns one persistent FocusNode', () {
    final source = File(
      'lib/views/reader/widgets/reader_keyboard_listener.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('class ReaderKeyboardListener extends StatefulWidget'),
    );
    expect(source, contains('late final FocusNode _focusNode'));
    expect(source, contains('_focusNode.dispose()'));
    expect(source, isNot(contains('focusNode: FocusNode()..requestFocus()')));
  });

  testWidgets('ReaderKeyboardListener keeps key handling after rebuild', (
    tester,
  ) async {
    var count = 0;

    Widget build() {
      return ChangeNotifierProvider<ListStateProvider>.value(
        value: ListStateProvider(),
        child: MaterialApp(
          home: ReaderKeyboardListener(
            handlers: {LogicalKeyboardKey.keyD: () => count++},
            child: const SizedBox.expand(),
          ),
        ),
      );
    }

    await tester.pumpWidget(build());
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.pumpWidget(build());
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);

    expect(count, 2);
  });
}
