import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/extension.dart';

enum ReadMode {
  /// 条漫模式
  vertical,

  /// 单页横向从左到右
  leftToRight,

  /// 单页横向从右到左
  rightToLeft,

  /// 双页横向从左到右
  doubleLeftToRight,

  /// 双页横向从右到左
  doubleRightToLeft,
}

ReadMode stringToReadMode(String mode) {
  return switch (mode) {
    'vertical' => ReadMode.vertical,
    'leftToRight' => ReadMode.leftToRight,
    'rightToLeft' => ReadMode.rightToLeft,
    'doubleLeftToRight' => ReadMode.doubleLeftToRight,
    'doubleRightToLeft' => ReadMode.doubleRightToLeft,
    _ => ReadMode.vertical,
  };
}

String readModeToString(ReadMode mode) {
  return switch (mode) {
    ReadMode.vertical => '连续从上到下',
    ReadMode.leftToRight => '单页从左到右',
    ReadMode.rightToLeft => '单页从右到左',
    ReadMode.doubleLeftToRight => '双页从左到右',
    ReadMode.doubleRightToLeft => '双页从右到左',
  };
}

typedef ReaderHandler =
    AsyncRequestHandler1<List<ChapterImage>, FetchChapterImagesPayload>;

class ReaderProvider with ChangeNotifier {
  bool _loading = false;
  List<ChapterImage> _images = [];
  Object? _error;

  bool get loading => _loading;
  List<ChapterImage> get images => _images;
  Object? get error => _error;
  VoidCallback get refresh => handler.refresh;

  set loading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  set images(List<ChapterImage> images) {
    _images = images;
    notifyListeners();
  }

  set error(Object? error) {
    _error = error;
    notifyListeners();
  }

  /// 章节图片获取
  late final handler = fetchChapterImages.useRequest(
    onBefore: (_) {
      _loading = true;
      _error = null;
      _images = [];
      Future.microtask(() => notifyListeners());
    },
    onSuccess: (data, _) {
      Log.info('Fetch chapter images success', data.toString());
      _images = data;
    },
    onError: (e, _) {
      Log.error('Fetch chapter images error', e);
      _error = e;
    },
    onFinally: (_) {
      _loading = false;
      Future.microtask(() => notifyListeners());
    },
  );

  /// 漫画id
  late String cid;

  /// 漫画名称
  late String title;

  /// 漫画所有章节
  late List<Chapter> chapters;

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

  /// 当前章节第几张图片
  int _currentImageIndex = 0;
  int get currentImageIndex => _currentImageIndex;
  set currentImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }

  /// 跳转到指定章节
  void go(Chapter chapter) {
    _currentChapter = chapter;
    _currentImageIndex = 0;
    notifyListeners();
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

  /// 多页阅读模式图片
  List<List<ChapterImage>> get multiPageImages => splitList(_images, 2);

  /// 阅读模式
  ReadMode _readMode = AppConf().readMode;
  ReadMode get readMode => _readMode;
  set readMode(ReadMode mode) {
    _readMode = mode;
    AppConf().readMode = mode;
    notifyListeners();
  }

  /// 是否是双页阅读模式
  bool get isDoublePage =>
      _readMode == ReadMode.doubleLeftToRight ||
      _readMode == ReadMode.doubleRightToLeft;

  /// 是否是从右到左阅读模式
  bool get isReverse =>
      _readMode == ReadMode.rightToLeft ||
      _readMode == ReadMode.doubleRightToLeft;

  /// 是否显示工具栏
  bool _showToolbar = false;
  bool get showToolbar => _showToolbar;
  set showToolbar(bool value) {
    _showToolbar = value;
    notifyListeners();
  }

  /// 切换工具栏显示状态
  void openOrCloseToolbar() {
    showToolbar = !showToolbar;
    // 根据工具栏状态切换系统UI模式
    SystemChrome.setEnabledSystemUIMode(
      showToolbar ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );
  }

  @override
  void dispose() {
    handler.dispose();
    super.dispose();
  }

  /// [id] 漫画id
  /// [title] 漫画标题
  /// [chapters] 漫画所有章节
  /// [currentChapter] 从第几章开始
  /// [currentImageIndex] 从第几张图片开始
  void initialize({
    required String id,
    required String title,
    required List<Chapter> chapters,
    Chapter? currentChapter,
    int? currentImageIndex,
  }) {
    cid = id;
    this.title = title;
    this.chapters = chapters;
    _currentChapter = currentChapter ?? chapters.first;
    _currentImageIndex = currentImageIndex ?? 0;
  }

  void reset() {
    _readMode = AppConf().readMode;
    _showToolbar = false;
  }
}
