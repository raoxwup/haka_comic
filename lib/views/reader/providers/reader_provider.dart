import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/http.dart' hide register;
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/download/fetch_local_images.dart';
import 'package:haka_comic/views/import_comics/fetch_import_images.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/views/reader/utils/image_preload_controller.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:volume_button_override/volume_button_override.dart';

extension BuildContextReader on BuildContext {
  ReaderProvider get reader => read<ReaderProvider>();
  ReaderProvider get watcher => watch<ReaderProvider>();
  T selector<T>(T Function(ReaderProvider) s) => select<ReaderProvider, T>(s);
}

typedef FetchImageHandler =
    RequestHandlerWithParams<List<ImageBase>, FetchChapterImagesPayload>;

typedef FetchImages =
    Future<List<ImageBase>> Function(FetchChapterImagesPayload payload);

class ReaderProvider extends RequestProvider {
  ReaderProvider({
    required ComicState state,
    FetchImages? fetchImages,
    Future<void> Function(ComicReadRecord record)? saveReadRecord,
    Duration readRecordDebounceDuration = const Duration(milliseconds: 50),
  }) {
    id = state.id;
    title = state.title;
    chapters = state.chapters;
    chapter = state.chapter;
    pageNo = state.pageNo;
    type = state.type;
    _saveReadRecord = saveReadRecord ?? _helper.insert;
    _readRecordDebounceDuration = readRecordDebounceDuration;

    final Future<List<ImageBase>> Function(FetchChapterImagesPayload) request =
        fetchImages ??
        switch (type) {
          ReaderType.network => fetchChapterImages,
          ReaderType.local => fetchLocalImages,
          ReaderType.import => fetchImportImages,
        };

    handler = request.useRequest(
      defaultParams: FetchChapterImagesPayload(
        id: state.id,
        order: chapter.order,
      ),
      onSuccess: (data, _) {
        Log.i('Fetch chapter images success', data.toString());
        preloadController.replaceItems(data);
        preloadController.onAnchorChanged([0]);
      },
      onError: (e, _) {
        Log.e('Fetch chapter images error', error: e);
      },
    );

    register(handler);
  }

  /// 读取的是本地图片还是网络图片
  late final ReaderType type;

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

  /// 隐藏工具栏（仅在显示时生效）
  void hideToolbar() {
    if (!showToolbar) return;
    openOrCloseToolbar();
  }

  /// 切换工具栏显示状态
  void openOrCloseToolbar() {
    Future.microtask(() {
      final willShowToolbar = !showToolbar;

      if (willShowToolbar) {
        if (_isPageTurning) {
          turnPageTimer?.cancel();
          turnPageTimer = null;
          _smoothTicker?.stop();
          _isPageTurnPausedByToolbar = true;
        }
      } else if (_isPageTurning && _isPageTurnPausedByToolbar) {
        if (_isSmoothScroll) {
          _smoothTicker?.start();
        } else {
          _startPageTurnTimer();
        }
        _isPageTurnPausedByToolbar = false;
      }

      showToolbar = willShowToolbar;
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
  List<ImageBase> get images => handler.state.data ?? [];

  ///多页模式下章节图片
  List<ImageBase>? _multiPageImagesSource;
  List<List<ImageBase>>? _multiPageImagesCache;
  List<List<ImageBase>> get multiPageImages {
    final source = images;
    final cache = _multiPageImagesCache;
    if (cache != null && identical(source, _multiPageImagesSource)) {
      return cache;
    }

    final next = splitList(source, 2);
    _multiPageImagesSource = source;
    _multiPageImagesCache = next;
    return next;
  }

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

  Timer? _pageNoTimer;
  int? _pendingReadRecordPageNo;
  late final Future<void> Function(ComicReadRecord record) _saveReadRecord;
  late final Duration _readRecordDebounceDuration;

  /// 更新当前页码并保存阅读记录，[index]始终保持为单页页码方便计算
  void onPageNoChanged(int index) {
    if (_pendingReadRecordPageNo == index) return;
    if (index == pageNo && _pendingReadRecordPageNo == null) return;
    _pageNoTimer?.cancel();
    if (index != pageNo) {
      pageNo = index;
    }
    _pendingReadRecordPageNo = index;
    _pageNoTimer = Timer(_readRecordDebounceDuration, () async {
      _pendingReadRecordPageNo = null;
      _saveReadRecord(
        ComicReadRecord(
          cid: id,
          chapterId: chapter.id,
          pageNo: index,
          chapterTitle: chapter.title,
        ),
      );
    });
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
    if (!itemScrollController.isAttached) return;

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

    if (AppConf().enablePageAnimation) {
      scrollOffsetController.animateScroll(
        offset: offset,
        duration: const Duration(milliseconds: 200),
      );
    } else {
      scrollOffsetController.scrollTo(offset);
    }
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

      if (AppConf().enablePageAnimation) {
        pageController.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      } else {
        pageController.jumpToPage(pageController.page!.round() - 1);
      }
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

      if (AppConf().enablePageAnimation) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      } else {
        pageController.jumpToPage(pageController.page!.round() + 1);
      }
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

  /// 自动翻页
  bool _isPageTurning = false;
  bool _isSmoothScroll = false;
  bool get isSmoothScroll => _isSmoothScroll;
  bool _isPageTurnPausedByToolbar = false;
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

  void _startPageTurnTimer() {
    turnPageTimer?.cancel();
    turnPageTimer = Timer.periodic(Duration(seconds: _interval), (timer) {
      if (handler.state case Loading()) return;
      next();
    });
  }

  /// 开始定时翻页
  void startPageTurn() {
    _isSmoothScroll = false;
    _isPageTurnPausedByToolbar = false;
    _startPageTurnTimer();
    isPageTurning = true;
  }

  /// 平滑滚动 Ticker
  Ticker? _smoothTicker;
  double _scrollSpeed = AppConf().scrollSpeed;
  double get scrollSpeed => _scrollSpeed;
  set scrollSpeed(double value) {
    _scrollSpeed = value;
    AppConf().scrollSpeed = value;
    notifyListeners();
  }

  void updateScrollSpeed(double speed) {
    scrollSpeed = speed;
  }

  /// 开始平滑滚动
  void startSmoothScroll(TickerProvider vsync) {
    _isSmoothScroll = true;
    _isPageTurnPausedByToolbar = false;
    _smoothTicker?.dispose();
    _smoothTicker = vsync.createTicker((_) {
      if (handler.state case Loading()) return;
      if (!itemScrollController.isAttached) return;
      if (pageNo == images.length - 1) {
        if (!isLastChapter) {
          goNext();
        } else {
          stopPageTurn();
          Toast.show(message: '没有下一章了');
        }
        return;
      }
      scrollOffsetController.scrollTo(_scrollSpeed);
    });
    _smoothTicker!.start();
    isPageTurning = true;
  }

  /// 关闭自动翻页（定时 & 平滑 通用）
  void stopPageTurn() {
    turnPageTimer?.cancel();
    turnPageTimer = null;
    _smoothTicker?.stop();
    _smoothTicker?.dispose();
    _smoothTicker = null;
    _isSmoothScroll = false;
    _isPageTurnPausedByToolbar = false;
    isPageTurning = false;
  }

  /// 更新定时翻页间隔
  void updateInterval(int interval) {
    this.interval = interval;
  }

  late ImagePreloadController<ImageBase> preloadController;

  /// 初始化图片预加载控制器
  void initPreloadController(BuildContext context) {
    preloadController = ImagePreloadController<ImageBase>(
      items: images,
      urlResolver: (image) => image.url,
      context: context,
      type: type,
      maxPreloadCount: AppConf().preloadImageCount,
    );
  }

  /// 更新预加载解码宽度（与显示端保持一致，保证 ImageCache 命中）
  void updatePreloadCacheWidth(int? cacheWidth) {
    if (preloadController.cacheWidth == cacheWidth) return;
    preloadController.cacheWidth = cacheWidth;
    // cacheWidth 变化会改变 ImageCache key，
    // 旧的已预加载记录必须失效，否则后续锚点落在这些 index 上时不会重新预解码
    preloadController.invalidatePreloaded();
  }

  final volumeController = VolumeButtonController();

  /// 音量+事件
  late final volumeUpAction = ButtonAction(
    id: ButtonActionId.volumeUp,
    onAction: prev,
  );

  /// 音量-事件
  late final volumeDownAction = ButtonAction(
    id: ButtonActionId.volumeDown,
    onAction: next,
  );

  @override
  void dispose() {
    pageController.dispose();
    turnPageTimer?.cancel();
    _smoothTicker?.dispose();
    preloadController.dispose();
    _pageNoTimer?.cancel();
    volumeController.stopListening();
    super.dispose();
  }
}
