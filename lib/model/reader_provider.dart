import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';

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
  int _pageNo = 0;
  int get pageNo => _pageNo;
  set pageNo(int index) {
    _pageNo = index;
    notifyListeners();
  }

  /// [id] 漫画id
  /// [title] 漫画标题
  /// [chapters] 漫画所有章节
  /// [currentChapter] 从第几章开始
  /// [pageNo] 从第几张图片开始
  void initialize({
    required String id,
    required String title,
    required List<Chapter> chapters,
    Chapter? currentChapter,
    int? pageNo,
  }) {
    cid = id;
    this.title = title;
    this.chapters = chapters;
    _currentChapter = currentChapter ?? chapters.first;
    _pageNo = pageNo ?? 0;
  }
}
