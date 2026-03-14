import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/widgets/app_bar.dart';
import 'package:haka_comic/views/reader/widgets/bottom.dart';
import 'package:haka_comic/views/reader/widgets/next_chapter.dart';
import 'package:haka_comic/views/reader/widgets/page_no_tag.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/widgets/reader_keyboard_listener.dart';
import 'package:haka_comic/views/reader/widgets/horizontal_list/horizontal_list.dart';
import 'package:haka_comic/views/reader/widgets/vertical_list/vertical_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Reader extends StatefulWidget {
  const Reader({super.key});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  @override
  void initState() {
    super.initState();

    context.reader.initPreloadController(context);

    // 设置沉浸式阅读模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    if (AppConf().enableVolume) {
      context.reader.volumeController.startListening(
        volumeUpAction: context.reader.volumeUpAction,
        volumeDownAction: context.reader.volumeDownAction,
      );
    }
  }

  @override
  void dispose() {
    // 恢复系统UI模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readMode = context.selector((state) => state.readMode);

    final chapterIndex = context.selector((state) => state.chapterIndex);

    final state = context.selector((state) => state.handler.state);

    final showPageNumbers = context.stateSelector((p) => p.showPageNumbers);

    final prev = context.reader.prev;
    final next = context.reader.next;

    final chapters = context.selector((state) => state.chapters);

    Widget listWidget = readMode.isVertical
        ? const VerticalList()
        : const HorizontalList();

    return Scaffold(
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: switch (state) {
              Success() => ReaderKeyboardListener(
                handlers: {
                  LogicalKeyboardKey.arrowLeft: prev,
                  LogicalKeyboardKey.arrowRight: next,
                  LogicalKeyboardKey.arrowUp: prev,
                  LogicalKeyboardKey.arrowDown: next,
                  LogicalKeyboardKey.pageUp: prev,
                  LogicalKeyboardKey.pageDown: next,
                  LogicalKeyboardKey.keyA: prev,
                  LogicalKeyboardKey.keyD: next,
                  LogicalKeyboardKey.audioVolumeUp: prev,
                  LogicalKeyboardKey.audioVolumeDown: next,
                },
                child: listWidget,
              ),
              Error(:final error) => ErrorPage(
                errorMessage: error.toString(),
                onRetry: context.reader.handler.refresh,
                canPop: true,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),

          if (showPageNumbers) const ReaderPageNoTag(),

          const ReaderNextChapter(),

          const ReaderAppBar(),

          const ReaderBottom(),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, context.top + 10, 0, 10),
              child: Text(
                '章节列表',
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ScrollablePositionedList.builder(
                initialScrollIndex: chapterIndex,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return ListTile(
                    enabled: index != chapterIndex,
                    title: Text(chapter.title),
                    onTap: () {
                      context.pop();
                      context.reader.go(chapter);
                    },
                  );
                },
                itemCount: chapters.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
