import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/mixin/request.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart' hide UseRequest1Extensions;
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/reader/state/comic_reader_state.dart';
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
    AsyncRequestHandlerWithParam<List<ChapterImage>, FetchChapterImagesPayload>;

class ReaderProvider with ChangeNotifier {
  ReaderProvider({required ComicReaderState state}) {
    cid = state.id;
    title = state.title;
    chapters = state.chapters;
    _currentChapter = state.chapter;
    pageNo = state.pageNo;
    handler = fetchChapterImages.useRequest(
      initParam: FetchChapterImagesPayload(
        id: state.id,
        order: _currentChapter.order,
      ),
      onSuccess: (data, _) {
        Log.info('Fetch chapter images success', data.toString());
      },
      onError: (e, _) {
        Log.error('Fetch chapter images error', e);
      },
      onFinally: (_) {
        notifyListeners();
      },
    );
  }

  late final BuildContext _context;

  void initContext(BuildContext context) => _context = context;

  /// 获取图片的handler
  late final FetchImageHandler handler;

  /// 漫画id
  late final String cid;

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
  List<ChapterImage> get images => handler.data ?? [];

  ///多页模式下章节图片
  List<List<ChapterImage>> get multiPageImages => splitList(images, 2);

  /// 章节总页数
  int get pageCount =>
      readMode.isDoublePage ? multiPageImages.length : images.length;

  /// 漫画当前阅读章节
  late Chapter _currentChapter;
  Chapter get currentChapter => _currentChapter;
  set currentChapter(Chapter chapter) {
    _currentChapter = chapter;
    notifyListeners();
  }

  /// 当前章节的索引
  int get currentChapterIndex => chapters.indexOf(currentChapter);

  /// 是否为第一章
  bool get isFirstChapter => currentChapter.uid == chapters.first.uid;

  /// 是否为最后一章
  bool get isLastChapter => currentChapter.uid == chapters.last.uid;

  /// 跳转到指定章节
  void go(Chapter chapter) {
    currentChapter = chapter;
    pageNo = 0;
    handler.run(FetchChapterImagesPayload(id: cid, order: chapter.order));
  }

  /// 下一章
  void goNext() {
    if (isLastChapter) return;
    final currentIndex = chapters.indexWhere(
      (chapter) => chapter.uid == currentChapter.uid,
    );
    final nextChapter = chapters[currentIndex + 1];
    go(nextChapter);
  }

  /// 上一章
  void goPrevious() {
    if (isFirstChapter) return;
    final currentIndex = chapters.indexWhere(
      (chapter) => chapter.uid == currentChapter.uid,
    );
    final previousChapter = chapters[currentIndex - 1];
    go(previousChapter);
  }

  /// 当前章节第几张图片
  int _pageNo = 0;
  int get pageNo => _pageNo;
  set pageNo(int index) {
    _pageNo = index;
    notifyListeners();
  }

  /// 获取正确的页码
  int get correctPageNo =>
      readMode.isDoublePage ? toCorrectMultiPageNo(pageNo, 2) : pageNo;

  /// 阅读记录数据库助手
  final _helper = ReadRecordHelper();

  /// 更新当前页码并保存阅读记录，[index]始终保持为单页页码方便计算
  void onPageNoChanged(int index) {
    if (index == pageNo) return;
    pageNo = index;
    _helper.insert(
      ComicReadRecord(
        cid: cid,
        chapterId: currentChapter.id,
        pageNo: index,
        chapterTitle: currentChapter.title,
      ),
    );
  }

  /// 底部工具栏Slider OnChanged
  void onSliderChanged(int index) {
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
      if (correctPageNo == pageCount - 1) {
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
      pageTurnForVertical(_context.height * AppConf().slipFactor * -1);
    } else {
      pageTurnForHorizontal(false);
    }
  }

  /// 向后翻页
  void next() {
    if (readMode.isVertical) {
      pageTurnForVertical(_context.height * AppConf().slipFactor);
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
      if (handler.loading) return;
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

  /// 是否按下了Ctrl
  bool _isCtrlPressed = false;
  bool get isCtrlPressed => _isCtrlPressed;
  set isCtrlPressed(bool value) {
    _isCtrlPressed = value;
    notifyListeners();
  }

  /// 条漫模式宽度
  double _verticalListWidthPercentage = AppConf().verticalListWidthRatio;
  double get verticalListWidth => _verticalListWidthPercentage;
  set verticalListWidth(double width) {
    _verticalListWidthPercentage = width;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    turnPageTimer?.cancel();
    super.dispose();
  }
}

class StartReaderState {
  /// 漫画id
  final String id;

  /// 漫画标题
  final String title;

  /// 漫画所有章节
  final List<Chapter> chapters;

  /// 当前阅读章节
  final Chapter? currentChapter;

  /// 当前阅读章节第几张图片
  final int? pageNo;

  StartReaderState({
    required this.id,
    required this.title,
    required this.chapters,
    this.currentChapter,
    this.pageNo,
  });
}
