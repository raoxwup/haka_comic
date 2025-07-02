import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class ReaderNextChapter extends StatelessWidget {
  const ReaderNextChapter({
    super.key,
    required this.isShow,
    required this.onPressed,
  });

  final bool isShow;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // final isShow =
    //     !loading && images.isNotEmpty && currentImageIndex >= images.length - 2;
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
              onPressed: onPressed,
              child: const Icon(Icons.skip_next),
            ),
          ),
        ),
      ),
    );
  }
}
