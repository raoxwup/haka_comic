import 'package:haka_comic/network/models.dart';

class InitializeReaderState {
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

  InitializeReaderState({
    required this.id,
    required this.title,
    required this.chapters,
    this.currentChapter,
    this.pageNo,
  });
}
