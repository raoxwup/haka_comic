import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/request.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';

enum ReadMode {
  /// 条漫模式
  vertical('连续从上到下'),

  /// 单页横向从左到右
  leftToRight('单页从左到右'),

  /// 单页横向从右到左
  rightToLeft('单页从右到左'),

  /// 双页横向从左到右
  doubleLeftToRight('双页从左到右'),

  /// 双页横向从右到左
  doubleRightToLeft('双页从右到左');

  final String displayName;

  const ReadMode(this.displayName);

  static ReadMode fromName(String? name) {
    return ReadMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => vertical,
    );
  }

  /// 是否为条漫阅读模式
  bool get isVertical => this == vertical;

  /// 是否为双页阅读模式
  bool get isDoublePage =>
      this == doubleLeftToRight || this == doubleRightToLeft;

  /// 是否是从右到左阅读模式
  bool get isReverse =>
      this == ReadMode.rightToLeft || this == ReadMode.doubleRightToLeft;
}

class ReaderProvider with ChangeNotifier {
  ReaderProvider({required StartReaderState state})
    : _verticalListWidthPercentage = AppConf().verticalListWidthRatio {
    cid = state.id;
    title = state.title;
    chapters = state.chapters;
    _currentChapter = state.currentChapter ?? chapters.first;
    pageNo = state.pageNo ?? 0;
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
    );
  }

  /// 获取图片的handler
  late final AsyncRequestHandlerWithParam<
    List<ChapterImage>,
    FetchChapterImagesPayload
  >
  handler;

  /// 漫画id
  late final String cid;

  /// 漫画名称
  late final String title;

  /// 漫画所有章节
  late final List<Chapter> chapters;

  /// 阅读模式
  ReadMode _readMode = AppConf().readMode;
  ReadMode get readMode => _readMode;
  set readMode(ReadMode mode) {
    _readMode = mode;
    AppConf().readMode = mode;
    notifyListeners();
  }

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

  /// 当前章节第几张图片
  int _pageNo = 0;
  int get pageNo => _pageNo;
  set pageNo(int index) {
    _pageNo = index;
    notifyListeners();
  }

  /// 是否按下了Ctrl
  bool _isCtrlPressed = false;
  bool get isCtrlPressed => _isCtrlPressed;
  set isCtrlPressed(bool value) {
    _isCtrlPressed = value;
    notifyListeners();
  }

  /// 条漫模式宽度
  late double _verticalListWidthPercentage;
  double get verticalListWidth => _verticalListWidthPercentage;
  set verticalListWidth(double width) {
    _verticalListWidthPercentage = width;
    notifyListeners();
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
