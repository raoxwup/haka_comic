import 'dart:math' as math show log;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/utils/extension.dart';

class ReaderImage extends StatefulWidget {
  const ReaderImage({
    super.key,
    required this.url,
    this.imageSize,
    this.fit = BoxFit.contain,
    required this.onImageSizeChanged,
  });

  // 图片url
  final String url;

  // 缓存的图片尺寸
  final ImageSize? imageSize;

  final BoxFit fit;

  // 是否使用缓存的尺寸
  final bool enableCache = true;

  // 尺寸回调
  final void Function(int width, int height) onImageSizeChanged;

  @override
  State<ReaderImage> createState() => _ReaderImageState();
}

class _ReaderImageState extends State<ReaderImage> {
  static const double _fallbackAspectRatio = 3 / 4;
  bool _isReported = false;

  Widget _buildPlaceholder(Widget child) {
    if (!widget.enableCache) {
      return Center(child: child);
    }

    final aspectRatio = widget.imageSize != null
        ? widget.imageSize!.width / widget.imageSize!.height
        : _fallbackAspectRatio;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.url,
      fit: widget.fit,
      cache: true,
      enableLoadState: true,
      handleLoadingProgress: true,
      headers: const {'Accept-Encoding': 'identity'},
      loadStateChanged: (state) {
        if (state.extendedImageLoadState == LoadState.loading) {
          final progress = state.loadingProgress;
          final bytes = progress?.cumulativeBytesLoaded ?? 0;

          double computeProgress(int bytes) {
            const double maxProgress = 0.9;
            const double scale = 50 * 1024;

            final p = math.log(bytes / scale + 1);
            final normalized = p / (p + 1);

            return (normalized * maxProgress).clamp(0.0, maxProgress);
          }

          final value = computeProgress(bytes);

          return _buildPlaceholder(
            CircularProgressIndicator(
              value: value,
              strokeWidth: 3,
              constraints: BoxConstraints.tight(const Size(28, 28)),
              backgroundColor: Colors.grey.shade300,
              color: context.colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          );
        }

        if (state.extendedImageLoadState == LoadState.completed) {
          final info = state.extendedImageInfo;
          if (info != null) {
            if (!_isReported) {
              widget.onImageSizeChanged(info.image.width, info.image.height);
              _isReported = true;
            }
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: state.completedWidget,
          );
        }

        return _buildPlaceholder(
          IconButton(
            onPressed: state.reLoadImage,
            icon: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }
}
