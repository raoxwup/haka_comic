import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/controller_provider.dart';
import 'package:haka_comic/views/reader/providers/images_provider.dart';
import 'package:haka_comic/views/reader/providers/read_mode_provider.dart';
import 'package:haka_comic/views/reader/providers/toolbar_provider.dart';
import 'package:haka_comic/utils/extension.dart'
    hide UseRequest1Extensions, AsyncRequestHandler;
import 'package:haka_comic/views/reader/app_bar.dart';
import 'package:haka_comic/views/reader/bottom.dart';
import 'package:haka_comic/views/reader/next_chapter.dart';
import 'package:haka_comic/views/reader/page_no_tag.dart';
import 'package:haka_comic/views/reader/widget/reader_keyboard_listener.dart';
import 'package:haka_comic/views/reader/widget/horizontal_list/horizontal_list.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/vertical_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:volume_button_override/volume_button_override.dart';

class Reader extends ConsumerStatefulWidget {
  const Reader({super.key});

  @override
  ConsumerState<Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<Reader> {
  /// 音量键控制器
  final volumeController = VolumeButtonController();

  /// 音量+事件
  late final volumeUpAction = ButtonAction(
    id: ButtonActionId.volumeUp,
    onAction: () => ref.read(listControllersProvider.notifier).prev(context),
  );

  /// 音量-事件
  late final volumeDownAction = ButtonAction(
    id: ButtonActionId.volumeDown,
    onAction: () => ref.read(listControllersProvider.notifier).next(context),
  );

  @override
  void initState() {
    super.initState();

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
    final readMode = ref.watch(readModeProvider);

    final isLastChapter = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((value) => value.isLastChapter),
    );

    final currentChapterIndex = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((value) => value.chapterIndex),
    );

    Widget listWidget = readMode.isVertical
        ? const VerticalList()
        : const HorizontalList();

    final listControllersNotifier = ref.read(listControllersProvider.notifier);
    void prev() => listControllersNotifier.prev(context);
    void next() => listControllersNotifier.next(context);

    final id = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((s) => s.id),
    );
    final order = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((s) => s.chapter.order),
    );

    final imagesAsyncValue = ref.watch(
      imagesProvider(FetchChapterImagesPayload(id: id, order: order)),
    );

    final chapters = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((s) => s.chapters),
    );

    return Scaffold(
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: switch (imagesAsyncValue) {
              AsyncValue(value: final _?) => ReaderKeyboardListener(
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
              AsyncValue(:final error?) => ErrorPage(
                errorMessage: error.toString(),
                onRetry: () => ref.invalidate(
                  imagesProvider(
                    FetchChapterImagesPayload(id: id, order: order),
                  ),
                ),
              ),
              AsyncValue() => const Center(child: CircularProgressIndicator()),
            },
          ),

          if (imagesAsyncValue.isRefreshing)
            Positioned.fill(
              child: Container(
                color: context.colorScheme.surfaceContainerLowest,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          const ReaderPageNoTag(),

          if (!isLastChapter) const ReaderNextChapter(),

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
                initialScrollIndex: currentChapterIndex,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return ListTile(
                    enabled: index != currentChapterIndex,
                    title: Text(chapter.title),
                    onTap: () {
                      context.pop();
                      ref.read(toolbarProvider.notifier).openOrCloseToolbar();
                      ref
                          .read(
                            comicReaderStateProvider(
                              routerPayloadCache,
                            ).notifier,
                          )
                          .go(chapter);
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
