import 'package:flutter/material.dart';
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
  bool get isFirstChapter => currentChapter.order == chapters.first.order;

  /// 是否为最后一章
  bool get isLastChapter => currentChapter.order == chapters.last.order;

  /// 跳转到指定章节
  void go(int index) {
    currentChapter = chapters[index];
  }

  /// 阅读模式
  ReadMode _readMode = AppConf().readMode;
  ReadMode get readMode => _readMode;
  set readMode(ReadMode mode) {
    _readMode = mode;
    AppConf().readMode = mode;
    notifyListeners();
  }

  @override
  dispose() {
    handler.dispose();
    super.dispose();
  }
}
