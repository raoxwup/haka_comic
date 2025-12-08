import 'package:flutter/material.dart';
import 'package:haka_comic/views/reader/reader_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:provider/provider.dart';

class ReaderNextChapter extends StatelessWidget {
  const ReaderNextChapter({super.key});

  @override
  Widget build(BuildContext context) {
    final isShow = context.select<ReaderProvider, bool>((p) {
      return !p.handler.loading &&
          p.images.isNotEmpty &&
          p.correctPageNo >= p.pageCount - 2;
    });

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
