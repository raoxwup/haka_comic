import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';

class ReaderNextChapter extends StatelessWidget {
  const ReaderNextChapter({super.key});

  @override
  Widget build(BuildContext context) {
    final handler = context.selector((p) => p.handler);
    final images = context.selector((p) => p.images);
    final pageNo = context.selector((p) => p.pageNo);
    final total = context.selector((p) => p.pageCount);
    final isLastChapter = context.selector((state) => state.isLastChapter);

    final isShow =
        !isLastChapter &&
        !handler.loading &&
        images.isNotEmpty &&
        pageNo >= total - 2;

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
              onPressed: context.reader.goNext,
              child: const Icon(Icons.skip_next),
            ),
          ),
        ),
      ),
    );
  }
}
