import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/request/request.dart';
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
import 'package:volume_button_override/volume_button_override.dart';

class Reader extends StatefulWidget {
  const Reader({super.key});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  /// 音量键控制器
  final volumeController = VolumeButtonController();

  /// 音量+事件
  late final volumeUpAction = ButtonAction(
    id: ButtonActionId.volumeUp,
    onAction: context.reader.prev,
  );

  /// 音量-事件
  late final volumeDownAction = ButtonAction(
    id: ButtonActionId.volumeDown,
    onAction: context.reader.next,
  );

  @override
  void initState() {
    super.initState();

    context.reader.initPreloadController(context);

    // 设置沉浸式阅读模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    if (AppConf().enableVolume) {
      volumeController.startListening(
        volumeUpAction: volumeUpAction,
        volumeDownAction: volumeDownAction,
      );
    }
  }

  @override
  void dispose() {
    // 恢复系统UI模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    volumeController.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readMode = context.selector((state) => state.readMode);

    final chapterIndex = context.selector((state) => state.chapterIndex);

    final state = context.selector((state) => state.handler.state);

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
              RequestSuccess() => ReaderKeyboardListener(
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
              RequestError(:final error) => ErrorPage(
                errorMessage: error.toString(),
                onRetry: context.reader.handler.refresh,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),

          const ReaderPageNoTag(),

          const ReaderNextChapter(),

          const ReaderAppBar(),

          const ReaderBottom(),
        ],
      ),
      drawer: Drawer(
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
                      context.reader.openOrCloseToolbar();
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
