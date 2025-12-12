import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/state/comic_reader_state.dart';

late ComicReaderState routerPayloadCache;

final comicReaderStateProvider = NotifierProvider.autoDispose
    .family<ComicReaderStateNotifier, ComicReaderState, ComicReaderState>(
      ComicReaderStateNotifier.new,
    );

class ComicReaderStateNotifier extends Notifier<ComicReaderState> {
  final ComicReaderState comicState;

  ComicReaderStateNotifier(this.comicState);

  @override
  build() => comicState;

  set chapter(Chapter chapter) {
    state = state.copyWith(chapter: chapter);
  }

  /// 跳转到指定章节
  void go(Chapter chapter) {
    state = state.copyWith(chapter: chapter, pageNo: 0);
    // state更新可能会触发imagesProvider请求，暂时存疑，后续测试
    // ref.watch(
    //   imagesProvider(FetchChapterImagesPayload(id: state.id, order: chapter.order)),
    // );
  }

  /// 下一章
  void goNext() {
    if (state.isLastChapter) return;
    final nextChapter = state.chapters[state.chapterIndex + 1];
    go(nextChapter);
  }

  /// 上一章
  void goPrevious() {
    if (state.isFirstChapter) return;
    final previousChapter = state.chapters[state.chapterIndex - 1];
    go(previousChapter);
  }

  set pageNo(int pageNo) {
    state = state.copyWith(pageNo: pageNo);
  }

  /// 更新当前页码并保存阅读记录，[index]始终保持为单页页码方便计算
  void onPageNoChanged(int index) {
    if (index == state.pageNo) return;
    pageNo = index;
    ReadRecordHelper().insert(
      ComicReadRecord(
        cid: state.id,
        chapterId: state.chapter.id,
        pageNo: index,
        chapterTitle: state.chapter.title,
      ),
    );
  }
}
