import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
// import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/model/reader_provider.dart';
// import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/read_record_helper.dart';
// import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/reader/widget/horizontal_list/horizontal_list.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/vertical_list.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/shadow_text.dart';
import 'package:haka_comic/widgets/with_blur.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const kBottomBarHeight = 105.0;

extension BuildContextReader on BuildContext {
  ReaderProvider get reader => read<ReaderProvider>();
  ReaderProvider get watchReader => watch<ReaderProvider>();
}

class Reader extends StatefulWidget {
  const Reader({super.key});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> /* with AutoRegisterHandlerMixin */ {
  /// 章节图片获取
  // late final _handler = fetchChapterImages.useRequest(
  //   onSuccess: (data, _) {
  //     Log.info('Fetch chapter images success', data.toString());
  //   },
  //   onError: (e, _) {
  //     Log.error('Fetch chapter images error', e);
  //   },
  // );

  /// 滚动控制器 - 用于精确控制列表滚动位置
  final ItemScrollController itemScrollController = ItemScrollController();
  final PageController pageController = PageController();

  /// 阅读记录数据库助手
  final _helper = ReadRecordHelper();

  /// 页面可见性变化回调
  /// 更新当前页码并保存阅读记录
  void onItemVisibleChanged(int index) {
    final i =
        context.reader.isDoublePage
            ? min(index * 2, context.reader.images.length)
            : index;
    context.reader.currentImageIndex = i;
    _helper.insert(
      ComicReadRecord(
        cid: context.reader.cid,
        chapterId: context.reader.currentChapter.id,
        pageNo: i,
        chapterTitle: context.reader.currentChapter.title,
      ),
    );
  }

  /// 跳转指定页
  void jumpToPage(int index) {
    context.reader.currentImageIndex = index;
    if (context.reader.readMode == ReadMode.vertical) {
      itemScrollController.jumpTo(index: index);
    } else {
      pageController.jumpToPage(index);
    }
  }

  @override
  // List<AsyncRequestHandler> registerHandler() => [_handler];
  @override
  void initState() {
    super.initState();

    // _handler.run(
    //   FetchChapterImagesPayload(
    //     id: context.reader.cid,
    //     order: context.reader.currentChapter.order,
    //   ),
    // );

    context.reader.handler.run(
      FetchChapterImagesPayload(
        id: context.reader.cid,
        order: context.reader.currentChapter.order,
      ),
    );
    // 设置沉浸式阅读模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // 恢复系统UI模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    pageController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    context.reader.reset();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final (
      readMode,
      currentImageIndex,
      isLastChapter,
      currentChapterIndex,
      refresh,
      loading,
      error,
      isDoublePage,
    ) = context.select<
      ReaderProvider,
      (ReadMode, int, bool, int, VoidCallback, bool, Object?, bool)
    >(
      (value) => (
        value.readMode,
        value.currentImageIndex,
        value.isLastChapter,
        value.currentChapterIndex,
        value.refresh,
        value.loading,
        value.error,
        value.isDoublePage,
      ),
    );

    Widget listWidget =
        readMode == ReadMode.vertical
            ? VerticalList(
              onItemVisibleChanged: onItemVisibleChanged,
              itemScrollController: itemScrollController,
            )
            : HorizontalList(
              onItemVisibleChanged: onItemVisibleChanged,
              pageController: pageController,
              isDoublePage: isDoublePage,
            );

    return Scaffold(
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // 主阅读区域
          Positioned.fill(
            child: BasePage(
              isLoading: loading,
              onRetry: refresh,
              error: error,
              child: listWidget,
            ),
          ),
          const ChapterPageNoTag(),

          if (!isLastChapter) const ReaderNextChapter(),

          const ReaderAppBar(),

          ReaderBottom(jumpToPage: jumpToPage),
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
                  final chapter = context.reader.chapters[index];
                  return ListTile(
                    enabled: index != currentChapterIndex,
                    title: Text(chapter.title),
                    onTap: () {
                      context.pop();
                      context.reader.openOrCloseToolbar();
                      context.reader.go(chapter);
                    },
                  );
                },
                itemCount: context.reader.chapters.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 页码
class ChapterPageNoTag extends StatelessWidget {
  const ChapterPageNoTag({super.key /* required this.totalPage */});

  // final int totalPage;

  @override
  Widget build(BuildContext context) {
    final (
      currentChapter,
      currentImageIndex,
      images,
      isDoublePage,
      multiPageImages,
    ) = context.select<
      ReaderProvider,
      (Chapter, int, List<ChapterImage>, bool, List<List<ChapterImage>>)
    >(
      (value) => (
        value.currentChapter,
        value.currentImageIndex,
        value.images,
        value.isDoublePage,
        value.multiPageImages,
      ),
    );
    var total = images.isEmpty ? 1 : images.length;
    total = isDoublePage ? multiPageImages.length : total;
    final pageNo =
        isDoublePage
            ? (currentImageIndex / 2).ceil() + 1
            : currentImageIndex + 1;
    return Positioned(
      left: context.left + 12,
      bottom: context.bottom + 12,
      width: context.width / 2,
      child: Row(
        spacing: 5,
        children: [
          Flexible(child: ShadowText(text: currentChapter.title)),
          ShadowText(text: '$pageNo / $total'),
        ],
      ),
    );
  }
}

/// 顶部工具栏
class ReaderAppBar extends StatelessWidget {
  const ReaderAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final top = context.top;
    final (showToolbar, readMode) = context
        .select<ReaderProvider, (bool, ReadMode)>(
          (value) => (value.showToolbar, value.readMode),
        );
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      top: showToolbar ? 0 : -(kToolbarHeight + top),
      left: 0,
      right: 0,
      height: kToolbarHeight + top,
      child: WithBlur(
        child: AppBar(
          leading: IconButton(
            icon: Icon(
              (isIos || isMacOS) ? Icons.arrow_back_ios_new : Icons.arrow_back,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            MenuAnchor(
              menuChildren:
                  ReadMode.values.map((mode) {
                    return MenuItemButton(
                      onPressed: () {
                        context.reader.readMode = mode;
                        context.reader.openOrCloseToolbar();
                      },
                      child: Row(
                        spacing: 5,
                        children: [
                          Text(readModeToString(mode)),
                          if (mode == readMode)
                            Icon(
                              Icons.done,
                              size: 16,
                              color: context.colorScheme.primary,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.chrome_reader_mode_outlined),
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                );
              },
            ),
          ],
          title: Text(context.reader.title),
          backgroundColor: context.colorScheme.surface.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

/// 底部工具栏
class ReaderBottom extends StatelessWidget {
  const ReaderBottom({super.key, required this.jumpToPage});

  final void Function(int) jumpToPage;

  @override
  Widget build(BuildContext context) {
    final (
      isFirst,
      isLast,
      showToolbar,
    ) = context.select<ReaderProvider, (bool, bool, bool)>(
      (value) => (value.isFirstChapter, value.isLastChapter, value.showToolbar),
    );
    final bottom = context.bottom;

    void onPressed(String action) {
      context.reader.openOrCloseToolbar();
      action == 'previous'
          ? context.reader.goPrevious()
          : context.reader.goNext();
    }

    return AnimatedPositioned(
      bottom: showToolbar ? 0 : -(bottom + kBottomBarHeight),
      left: 0,
      right: 0,
      height: bottom + kBottomBarHeight,
      duration: const Duration(milliseconds: 250),
      child: WithBlur(
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
          decoration: BoxDecoration(
            color: context.colorScheme.surface.withValues(alpha: 0.92),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: isFirst ? null : () => onPressed('previous'),
                  ),
                  Expanded(child: PageSlider(onChanged: jumpToPage)),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.skip_next),
                    onPressed: isLast ? null : () => onPressed('next'),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: context.colorScheme.onSurface,
                      ),
                      label: const Text('章节'),
                      icon: const Icon(Icons.menu),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slider
class PageSlider extends StatelessWidget {
  final ValueChanged<int> onChanged;

  const PageSlider({required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final (currentImageIndex, images, isDoublePage, multiPageImages) = context
        .select<
          ReaderProvider,
          (int, List<ChapterImage>, bool, List<List<ChapterImage>>)
        >(
          (value) => (
            value.currentImageIndex,
            value.images,
            value.isDoublePage,
            value.multiPageImages,
          ),
        );

    final total = isDoublePage ? multiPageImages.length : images.length;

    if (total <= 1) return const SizedBox.shrink();

    final value =
        isDoublePage ? (currentImageIndex / 2).ceil() : currentImageIndex;

    return Slider(
      value: value.toDouble(),
      min: 0,
      max: (total - 1).toDouble(),
      divisions: total - 1,
      label: '${value + 1}',
      onChanged: (value) => onChanged(value.toInt()),
    );
  }
}

/// 构建下一章浮动按钮
/// 仅在接近章节末尾时显示
class ReaderNextChapter extends StatelessWidget {
  const ReaderNextChapter({super.key});

  @override
  Widget build(BuildContext context) {
    final (currentImageIndex, images, loading) = context
        .select<ReaderProvider, (int, List<ChapterImage>, bool)>(
          (value) => (value.currentImageIndex, value.images, value.loading),
        );

    final isShow =
        !loading && images.isNotEmpty && currentImageIndex >= images.length - 2;
    return Positioned(
      right: context.right + 16,
      bottom: context.bottom + 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isShow ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isShow ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isShow,
            child: FloatingActionButton(
              onPressed: context.reader.goNext,
              child: const Icon(Icons.skip_next),
            ),
          ),
        ),
      ),
    );
  }
}
