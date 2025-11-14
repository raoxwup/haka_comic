import 'dart:async';
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
import 'package:haka_comic/views/reader/page_turn_toolbar.dart';
import 'package:haka_comic/views/reader/widget/horizontal_list/horizontal_list.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/vertical_list.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/toast.dart';
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

  /// 底部工具栏Slider OnChanged
  void onSliderChanged(int index) {
    context.reader.pageNo = index;
    if (_readMode.isVertical) {
      _itemScrollController.jumpTo(index: index);
    } else {
      _pageController.jumpToPage(index);
    }
  }

  /// VerticalList 跳转 offset
  void _pageTurnForVertical(double offset) {
    final reader = context.reader;
    if (reader.pageNo == 0 && offset < 0) {
      if (!reader.isFirstChapter) {
        goPrevious();
      } else {
        Toast.show(message: '没有上一章了');
      }
      return;
    }

    if (reader.pageNo == _images.length - 1 && offset > 0) {
      if (!reader.isLastChapter) {
        goNext();
      } else {
        _stopPageTurn();
        Toast.show(message: '没有下一章了');
      }
      return;
    }

    _scrollOffsetController.animateScroll(
      offset: offset,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// HorizontalList 翻页
  void _pageTurnForHorizontal([bool isTurnNext = true]) {
    final reader = context.reader;

    void previousPage() {
      if (reader.pageNo == 0) {
        if (!reader.isFirstChapter) {
          goPrevious();
        } else {
          Toast.show(message: '没有上一章了');
        }
        return;
      }

      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }

    void nextPage() {
      final correctPageNo = _readMode.isDoublePage
          ? toCorrectMultiPageNo(reader.pageNo, 2)
          : reader.pageNo;

      final itemCount = _readMode.isDoublePage
          ? _multiPageImages.length
          : _images.length;

      if (correctPageNo == itemCount - 1) {
        if (!reader.isLastChapter) {
          goNext();
        } else {
          _stopPageTurn();
          Toast.show(message: '没有下一章了');
        }
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }

    isTurnNext ? nextPage() : previousPage();
  }

  /// 音量键控制器
  final volumeController = VolumeButtonController();

  /// 音量+事件
  late final volumeUpAction = ButtonAction(
    id: ButtonActionId.volumeUp,
    onAction: () {
      if (_readMode.isVertical) {
        _pageTurnForVertical(context.height * AppConf().slipFactor * -1);
      } else {
        _pageTurnForHorizontal(false);
      }
    },
  );

  /// 音量-事件
  late final volumeDownAction = ButtonAction(
    id: ButtonActionId.volumeDown,
    onAction: () {
      if (_readMode.isVertical) {
        _pageTurnForVertical(context.height * AppConf().slipFactor);
      } else {
        _pageTurnForHorizontal();
      }
    },
  );

  // 定时翻页
  bool _isPageTurning = false;
  bool _readyToPageTurning = false;
  Timer? _turnPageTimer;
  int _interval = AppConf().interval;

  void _startPageTurn() {
    _turnPageTimer?.cancel();
    _turnPageTimer = Timer.periodic(Duration(seconds: _interval), (timer) {
      if (_handler.isLoading) return;
      if (_readMode.isVertical) {
        _pageTurnForVertical(context.height * AppConf().slipFactor);
      } else {
        _pageTurnForHorizontal();
      }
    });
    setState(() {
      _isPageTurning = true;
    });
  }

  void _stopPageTurn() {
    _turnPageTimer?.cancel();
    setState(() {
      _isPageTurning = false;
    });
  }

  void _updateInterval(int interval) {
    setState(() {
      _interval = interval;
      AppConf().interval = interval;
    });
    if (_isPageTurning) {
      _startPageTurn();
    }
  }

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
    _turnPageTimer?.cancel();
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

    Widget listWidget = _readMode.isVertical
        ? VerticalList(
            onItemVisibleChanged: onPageNoChanged,
            itemScrollController: _itemScrollController,
            openOrCloseToolbar: openOrCloseToolbar,
            scrollOffsetController: _scrollOffsetController,
            images: _images,
            action: action,
            pageTurn: _pageTurnForVertical,
          )
        : HorizontalList(
            onItemVisibleChanged: onPageNoChanged,
            pageController: _pageController,
            isDoublePage: _readMode.isDoublePage,
            openOrCloseToolbar: openOrCloseToolbar,
            images: _images,
            multiPageImages: _multiPageImages,
            isReverse: _readMode.isReverse,
            action: action,
            pageTurn: _pageTurnForHorizontal,
          );

    final total = _readMode.isDoublePage
        ? _multiPageImages.length
        : _images.length;

    final correctPageNo = _readMode.isDoublePage
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

          !_isPageTurning
              ? ReaderBottom(
                  onSliderChanged: onSliderChanged,
                  showToolbar: _showToolbar,
                  total: total,
                  pageNo: correctPageNo,
                  isVerticalMode: _readMode.isVertical,
                  action: action,
                  openOrCloseToolbar: () {
                    openOrCloseToolbar();
                    setState(() {
                      _readyToPageTurning = true;
                    });
                  },
                  startPageTurn: _readyToPageTurning ? _startPageTurn : null,
                )
              : PageTurnToolbar(
                  showToolbar: _showToolbar,
                  interval: _interval,
                  onIntervalChanged: _updateInterval,
                  openOrCloseToolbar: () {
                    openOrCloseToolbar();
                    setState(() {
                      _readyToPageTurning = false;
                    });
                  },
                  stopPageTurn: !_readyToPageTurning ? _stopPageTurn : null,
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
