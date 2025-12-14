import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/http.dart' hide register;
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

extension BuildContextReader on BuildContext {
  ReaderProvider get reader => read<ReaderProvider>();
  ReaderProvider get watcher => watch<ReaderProvider>();
  T selector<T>(T Function(ReaderProvider) s) => select<ReaderProvider, T>(s);
}

typedef FetchImageHandler =
    RequestHandlerWithParams<List<ChapterImage>, FetchChapterImagesPayload>;

class ReaderProvider extends RequestProvider {
  ReaderProvider({required ComicState state}) {
    id = state.id;
    title = state.title;
    chapters = state.chapters;
    chapter = state.chapter;
    pageNo = state.pageNo;

    handler = fetchChapterImages.useRequest(
      defaultParams: FetchChapterImagesPayload(
        id: state.id,
        order: chapter.order,
      ),
      onSuccess: (data, _) {
        Log.info('Fetch chapter images success', data.toString());
      },
      onError: (e, _) {
        Log.error('Fetch chapter images error', e);
      },
    );

    register(handler);
  }

  /// 获取图片的handler
  late final FetchImageHandler handler;

  /// 漫画id
  late final String id;

  /// 漫画名称
  late final String title;

  /// 漫画所有章节
  late final List<Chapter> chapters;

  /// 是否显示顶部/底部工具栏
  bool showToolbar = false;

  /// 切换工具栏显示状态
  void openOrCloseToolbar() {
    Future.microtask(() {
      showToolbar = !showToolbar;
      SystemChrome.setEnabledSystemUIMode(
        showToolbar ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
      );
      notifyListeners();
    });
  }

  /// 阅读模式
  ReadMode _readMode = AppConf().readMode;
  ReadMode get readMode => _readMode;
  set readMode(ReadMode mode) {
    _readMode = mode;
    AppConf().readMode = mode;
    notifyListeners();
  }

  /// 滚动控制器 - 用于精确控制列表滚动位置
  final scrollOffsetController = ScrollOffsetController();
  final itemScrollController = ItemScrollController();
  final pageController = PageController();

  /// 章节图片
  List<ChapterImage> get images =>
      handler.state.maybeWhen(success: (data) => data, orElse: () => []);

  ///多页模式下章节图片
  List<List<ChapterImage>> get multiPageImages => splitList(images, 2);

  /// 章节总页数
  int get pageCount =>
      readMode.isDoublePage ? multiPageImages.length : images.length;

  /// 漫画当前阅读章节
  late Chapter _chapter;
  Chapter get chapter => _chapter;
  set chapter(Chapter chapter) {
    _chapter = chapter;
    notifyListeners();
  }

  /// 当前章节的索引
  int get chapterIndex =>
      chapters.indexWhere((chapter) => chapter.uid == _chapter.uid);

  /// 是否为第一章
  bool get isFirstChapter => chapter.uid == chapters.first.uid;

  /// 是否为最后一章
  bool get isLastChapter => chapter.uid == chapters.last.uid;

  /// 跳转到指定章节
  void go(Chapter chapter) {
    this.chapter = chapter;
    pageNo = 0;
    handler.run(FetchChapterImagesPayload(id: id, order: chapter.order));
  }

  /// 下一章
  void goNext() {
    if (isLastChapter) return;
    final nextChapter = chapters[chapterIndex + 1];
    go(nextChapter);
  }

  /// 上一章
  void goPrevious() {
    if (isFirstChapter) return;
    final previousChapter = chapters[chapterIndex - 1];
    go(previousChapter);
  }

  /// 当前章节第几张图片
  int _pageNo = 0;
  int get pageNo =>
      readMode.isDoublePage ? toCorrectMultiPageNo(_pageNo, 2) : _pageNo;
  set pageNo(int index) {
    _pageNo = index;
    notifyListeners();
  }

  /// 阅读记录数据库助手
  final _helper = ReadRecordHelper();

  /// 更新当前页码并保存阅读记录，[index]始终保持为单页页码方便计算
  void onPageNoChanged(int index) {
    if (index == pageNo) return;
    pageNo = index;
    _helper.insert(
      ComicReadRecord(
        cid: id,
        chapterId: chapter.id,
        pageNo: index,
        chapterTitle: chapter.title,
      ),
    );
  }

  /// 底部工具栏Slider OnChanged
  void onSliderChanged(int index) {
    pageNo = index;
    if (readMode.isVertical) {
      itemScrollController.jumpTo(index: index);
    } else {
      pageController.jumpToPage(index);
    }
  }

  /// VerticalList 跳转 offset
  void pageTurnForVertical(double offset) {
    if (pageNo == 0 && offset < 0) {
      if (!isFirstChapter) {
        goPrevious();
      } else {
        Toast.show(message: '没有上一章了');
      }
      return;
    }

    if (pageNo == images.length - 1 && offset > 0) {
      if (!isLastChapter) {
        goNext();
      } else {
        stopPageTurn();
        Toast.show(message: '没有下一章了');
      }
      return;
    }

    scrollOffsetController.animateScroll(
      offset: offset,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// HorizontalList 翻页
  void pageTurnForHorizontal([bool isTurnNext = true]) {
    void previousPage() {
      if (pageNo == 0) {
        if (!isFirstChapter) {
          goPrevious();
        } else {
          Toast.show(message: '没有上一章了');
        }
        return;
      }

      pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }

    void nextPage() {
      if (pageNo == pageCount - 1) {
        if (!isLastChapter) {
          goNext();
        } else {
          stopPageTurn();
          Toast.show(message: '没有下一章了');
        }
        return;
      }

      pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }

    isTurnNext ? nextPage() : previousPage();
  }

  /// 向前翻页
  void prev() {
    if (readMode.isVertical) {
      pageTurnForVertical(screenHeight * AppConf().slipFactor * -1);
    } else {
      pageTurnForHorizontal(false);
    }
  }

  /// 向后翻页
  void next() {
    if (readMode.isVertical) {
      pageTurnForVertical(screenHeight * AppConf().slipFactor);
    } else {
      pageTurnForHorizontal();
    }
  }

  /// 定时翻页
  bool _isPageTurning = false;
  bool get isPageTurning => _isPageTurning;
  set isPageTurning(bool value) {
    _isPageTurning = value;
    notifyListeners();
  }

  /// 定时翻页定时器
  Timer? turnPageTimer;

  /// 定时翻页间隔
  int _interval = AppConf().interval;
  int get interval => _interval;
  set interval(int interval) {
    _interval = interval;
    AppConf().interval = interval;
    notifyListeners();
  }

  /// 开始定时翻页
  void startPageTurn() {
    turnPageTimer?.cancel();
    turnPageTimer = Timer.periodic(Duration(seconds: _interval), (timer) {
      if (handler.state case RequestState.loading) return;
      next();
    });
    isPageTurning = true;
  }

  /// 关闭定时翻页
  void stopPageTurn() {
    turnPageTimer?.cancel();
    isPageTurning = false;
  }

  /// 更新定时翻页间隔
  void updateInterval(int interval) {
    this.interval = interval;
    if (isPageTurning) {
      startPageTurn();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    turnPageTimer?.cancel();
    super.dispose();
  }
}
