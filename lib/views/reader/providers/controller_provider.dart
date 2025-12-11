import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/views/reader/providers/images_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/state/reader_state.dart';

class ReaderController {
  final Ref ref;

  ReaderController(this.ref);

  ReaderState get state => ref.read(readerStateProvider);
  ReaderStateNotifier get notifier => ref.read(readerStateProvider.notifier);

  // late BuildContext _context;
  // void initContext(BuildContext context) => _context = context;

  List<ChapterImage> get images => ref
      .read(
        imagesProvider(
          FetchChapterImagesPayload(
            id: state.id,
            order: state.currentChapter.order,
          ),
        ),
      )
      .maybeWhen(orElse: () => [], data: (images) => images);

  List<List<ChapterImage>> get multiPageImages => splitList(images, 2);
}

final readerControllerProvider = Provider.autoDispose<ReaderController>(
  (ref) => ReaderController(ref),
);
