import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:haka_comic/network/models.dart';

part 'comic_reader_state.freezed.dart';

@freezed
abstract class ComicReaderState with _$ComicReaderState {
  const ComicReaderState._();

  const factory ComicReaderState({
    /// 漫画id
    required String id,

    /// 漫画标题
    required String title,

    /// 漫画章节
    required List<Chapter> chapters,

    /// 当前章节
    required Chapter chapter,

    /// 当前页码
    required int pageNo,
  }) = _ComicReaderState;

  /// 当前章节的索引
  int get chapterIndex =>
      chapters.indexWhere((chapter) => chapter.uid == this.chapter.uid);

  /// 是否是第一章
  bool get isFirstChapter => chapter.uid == chapters.first.uid;

  /// 是否是最后一章
  bool get isLastChapter => chapter.uid == chapters.last.uid;
}
