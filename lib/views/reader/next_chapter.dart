import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/images_provider.dart';
import 'package:haka_comic/utils/extension.dart';

class ReaderNextChapter extends ConsumerWidget {
  const ReaderNextChapter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comicReaderStateProvider(routerPayloadCache));
    final notifier = ref.read(
      comicReaderStateProvider(routerPayloadCache).notifier,
    );
    final images = state.images;
    final p = state.correctPageNo;
    final total = state.correctPageCount;
    final imagesAsyncValue = ref.watch(
      imagesProvider(
        FetchChapterImagesPayload(id: state.id, order: state.chapter.order),
      ),
    );

    final isShow =
        !imagesAsyncValue.isLoading && images.isNotEmpty && p >= total - 2;

    return Positioned(
      right: context.right + 16,
      bottom: context.bottom + 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isShow ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isShow ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isShow,
            child: FloatingActionButton(
              onPressed: notifier.goNext,
              child: const Icon(Icons.skip_next),
            ),
          ),
        ),
      ),
    );
  }
}
