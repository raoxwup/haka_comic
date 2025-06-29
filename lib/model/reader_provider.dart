import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
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

class ReaderProvider with ChangeNotifier {
  /// 章节图片获取
  late final handler = fetchChapterImages.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch chapter images success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch chapter images error', e);
    },
    onFinally: (_) => notifyListeners(),
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

  /// 初始化应该加载到第几张图片
  int get initialIndex => _currentImageIndex;

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

  /// 阅读器Size
  late Size size;
  Size get readerSize => size;
  set readerSize(Size newSize) {
    size = newSize;
    notifyListeners();
  }

  @override
  void dispose() {
    handler.dispose();
    super.dispose();
  }

  /// 初始化一些变量
  void initialize({
    required String id,
    required String title,
    required List<Chapter> chapters,
    required Chapter currentChapter,
    required int currentImageIndex,
  }) {
    cid = id;
    this.title = title;
    this.chapters = chapters;
    _currentChapter = currentChapter;
    _currentImageIndex = currentImageIndex;
  }
}
