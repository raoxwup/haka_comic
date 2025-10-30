import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/reader/app_bar.dart';
import 'package:haka_comic/views/reader/bottom.dart';
import 'package:haka_comic/views/reader/next_chapter.dart';
import 'package:haka_comic/views/reader/page_no_tag.dart';
import 'package:haka_comic/views/reader/widget/horizontal_list/horizontal_list.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/vertical_list.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:volume_button_override/volume_button_override.dart';

extension BuildContextReader on BuildContext {
  ReaderProvider get reader => read<ReaderProvider>();
  ReaderProvider get watchReader => watch<ReaderProvider>();
}

class Reader extends StatefulWidget {
  const Reader({super.key});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> with AutoRegisterHandlerMixin {
  /// 章节图片获取
  late final _handler = fetchChapterImages.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch chapter images success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch chapter images error', e);
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  /// 章节图片
  List<ChapterImage> get _images => _handler.data ?? [];

  /// 双页章节图片
  List<List<ChapterImage>> get _multiPageImages => splitList(_images, 2);

  /// 滚动控制器 - 用于精确控制列表滚动位置
  final _scrollOffsetController = ScrollOffsetController();
  final _itemScrollController = ItemScrollController();
  final _pageController = PageController();

  /// 阅读模式
  ReadMode _readMode = AppConf().readMode;

  /// 修改阅读模式
  void _setReadMode(ReadMode mode) {
    setState(() {
      _readMode = mode;
      AppConf().readMode = mode;
    });
  }

  /// 是否是双页阅读模式
  bool get isDoublePage =>
      _readMode == ReadMode.doubleLeftToRight ||
      _readMode == ReadMode.doubleRightToLeft;

  /// 是否是从右到左阅读模式
  bool get isReverse =>
      _readMode == ReadMode.rightToLeft ||
      _readMode == ReadMode.doubleRightToLeft;

  /// 是否显示顶部/底部工具栏
  bool _showToolbar = false;

  /// 切换工具栏显示状态
  void openOrCloseToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
      SystemChrome.setEnabledSystemUIMode(
        _showToolbar ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
      );
    });
  }

  /// 跳转到指定章节
  void go(Chapter chapter) {
    context.reader.currentChapter = chapter;
    context.reader.pageNo = 0;
    _handler.run(
      FetchChapterImagesPayload(id: context.reader.cid, order: chapter.order),
    );
  }

  /// 下一章
  void goNext() {
    final reader = context.reader;
    if (reader.isLastChapter) return;
    final currentIndex = reader.chapters.indexWhere(
      (chapter) => chapter.uid == reader.currentChapter.uid,
    );
    final nextChapter = reader.chapters[currentIndex + 1];
    go(nextChapter);
  }

  /// 上一章
  void goPrevious() {
    final reader = context.reader;
    if (reader.isFirstChapter) return;
    final currentIndex = reader.chapters.indexWhere(
      (chapter) => chapter.uid == reader.currentChapter.uid,
    );
    final previousChapter = reader.chapters[currentIndex - 1];
    go(previousChapter);
  }

  /// 阅读记录数据库助手
  final _helper = ReadRecordHelper();

  /// 更新当前页码并保存阅读记录，[index]始终保持为单页页码方便计算
  void onPageNoChanged(int index) {
    final reader = context.reader;
    if (index == reader.pageNo) return;
    reader.pageNo = index;
    _helper.insert(
      ComicReadRecord(
        cid: reader.cid,
        chapterId: reader.currentChapter.id,
        pageNo: index,
        chapterTitle: reader.currentChapter.title,
      ),
    );
  }

  /// 跳转指定页
  void toPageNo(int index) {
    context.reader.pageNo = index;
    if (_readMode == ReadMode.vertical) {
      _itemScrollController.jumpTo(index: index);
    } else {
      _pageController.jumpToPage(index);
    }
  }

  /// 音量键控制器
  final volumeController = VolumeButtonController();

  /// 音量+事件
  late final volumeUpAction = ButtonAction(
    id: ButtonActionId.volumeUp,
    onAction: () {
      if (_readMode == ReadMode.vertical) {
        _scrollOffsetController.animateScroll(
          offset: context.height * AppConf().slipFactor * -1,
          duration: const Duration(milliseconds: 200),
        );
      } else {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      }
    },
  );

  /// 音量-事件
  late final volumeDownAction = ButtonAction(
    id: ButtonActionId.volumeDown,
    onAction: () {
      if (_readMode == ReadMode.vertical) {
        _scrollOffsetController.animateScroll(
          offset: context.height * AppConf().slipFactor,
          duration: const Duration(milliseconds: 200),
        );
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      }
    },
  );

  @override
  void initState() {
    super.initState();

    _handler.run(
      FetchChapterImagesPayload(
        id: context.reader.cid,
        order: context.reader.currentChapter.order,
      ),
    );

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
    _pageController.dispose();
    volumeController.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (
      isLastChapter,
      isFirstChapter,
      currentChapter,
      currentChapterIndex,
      pageNo,
    ) = context.select<ReaderProvider, (bool, bool, Chapter, int, int)>(
      (value) => (
        value.isLastChapter,
        value.isFirstChapter,
        value.currentChapter,
        value.currentChapterIndex,
        value.pageNo,
      ),
    );

    VoidCallback? action(ReaderBottomActionType type) {
      return switch (type) {
        ReaderBottomActionType.previous => isFirstChapter ? null : goPrevious,
        ReaderBottomActionType.next => isLastChapter ? null : goNext,
      };
    }

    Widget listWidget = _readMode == ReadMode.vertical
        ? VerticalList(
            onItemVisibleChanged: onPageNoChanged,
            itemScrollController: _itemScrollController,
            openOrCloseToolbar: openOrCloseToolbar,
            scrollOffsetController: _scrollOffsetController,
            images: _images,
            action: action,
          )
        : HorizontalList(
            onItemVisibleChanged: onPageNoChanged,
            pageController: _pageController,
            isDoublePage: isDoublePage,
            openOrCloseToolbar: openOrCloseToolbar,
            images: _images,
            multiPageImages: _multiPageImages,
            isReverse: isReverse,
            action: action,
          );

    final total = isDoublePage ? _multiPageImages.length : _images.length;
    final correctPageNo = isDoublePage
        ? toCorrectMultiPageNo(pageNo, 2)
        : context.reader.pageNo;

    return Scaffold(
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: BasePage(
              isLoading: _handler.isLoading,
              onRetry: _handler.refresh,
              error: _handler.error,
              child: listWidget,
            ),
          ),

          ReaderPageNoTag(
            pageNo: correctPageNo,
            total: total,
            title: currentChapter.title,
          ),

          if (!isLastChapter)
            ReaderNextChapter(
              isShow:
                  !_handler.isLoading &&
                  _images.isNotEmpty &&
                  correctPageNo >= total - 2,
              onPressed: goNext,
            ),

          ReaderAppBar(
            readMode: _readMode,
            showToolbar: _showToolbar,
            onReadModeChanged: (mode) {
              _setReadMode(mode);
              openOrCloseToolbar();
            },
          ),

          ReaderBottom(
            onPageNoChanged: toPageNo,
            showToolbar: _showToolbar,
            total: total,
            pageNo: correctPageNo,
            isVerticalMode: _readMode == ReadMode.vertical,
            action: action,
          ),
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
                      openOrCloseToolbar();
                      go(chapter);
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

/// 单页页码转换为正确的多页页码
int toCorrectMultiPageNo(int pageNo, int pageSize) {
  return pageNo ~/ pageSize;
}

/// 多页页码转换为正确的单页页码
int toCorrectSinglePageNo(int pageNo, int pageSize) {
  return pageNo * pageSize;
}

/// [pageSize]页页码转换为[anotherPageSize]页页码
int toAnotherMultiPageNo(int pageNo, int pageSize, int anotherPageSize) {
  return (pageNo * pageSize) ~/ anotherPageSize;
}
