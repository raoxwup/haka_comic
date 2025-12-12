import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/views/reader/providers/images_provider.dart';
import 'package:haka_comic/views/reader/providers/read_mode_provider.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';

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

    required WidgetRef ref,
  }) = _ComicReaderState;

  /// 当前章节的索引
  int get chapterIndex =>
      chapters.indexWhere((chapter) => chapter.uid == this.chapter.uid);

  /// 是否是第一章
  bool get isFirstChapter => chapter.uid == chapters.first.uid;

  /// 是否是最后一章
  bool get isLastChapter => chapter.uid == chapters.last.uid;

  /// 获取页码
  int get correctPageNo => ref.read(readModeProvider).isDoublePage
      ? toCorrectMultiPageNo(pageNo, 2)
      : pageNo;

  /// 章节所有图片
  List<ChapterImage> get images => ref
      .watch(
        imagesProvider(FetchChapterImagesPayload(id: id, order: chapter.order)),
      )
      .maybeWhen(data: (images) => images, orElse: () => []);

  List<List<ChapterImage>> get multiImages => splitList(images, 2);

  int get correctPageCount => ref.watch(readModeProvider).isDoublePage
      ? multiImages.length
      : images.length;
}
