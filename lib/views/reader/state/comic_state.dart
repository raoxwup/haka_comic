import 'package:haka_comic/network/models.dart';

enum ReaderType { network, local }

class ComicState {
  /// 漫画id
  final String id;

  /// 漫画标题
  final String title;

  /// 漫画章节
  final List<Chapter> chapters;

  /// 当前章节
  final Chapter chapter;

  /// 当前页码
  final int pageNo;

  final ReaderType type;

  const ComicState({
    required this.id,
    required this.title,
    required this.chapters,
    required this.chapter,
    required this.pageNo,
    this.type = ReaderType.network,
  });
}
