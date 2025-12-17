import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';

class ReaderImage extends StatefulWidget {
  const ReaderImage({
    super.key,
    required this.url,
    this.imageSize,
    this.enableCache = true,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.timeRetry = const Duration(milliseconds: 300),
    required this.onImageSizeChanged,
  });

  // 图片url
  final String url;

  // 缓存的图片尺寸
  final ImageSize? imageSize;

  final BoxFit fit;

  // 是否使用缓存的尺寸
  final bool enableCache;

  final FilterQuality filterQuality;

  final Duration timeRetry;

  // 尺寸回调
  final void Function(int width, int height) onImageSizeChanged;

  @override
  State<ReaderImage> createState() => _ReaderImageState();
}

class _ReaderImageState extends State<ReaderImage> {
  static const double _fallbackAspectRatio = 3 / 4;
  bool _isReported = false;

  Widget _buildPlaceholder(Widget child, [Key? key]) {
    if (!widget.enableCache) {
      return Center(key: key, child: child);
    }

    final aspectRatio = widget.imageSize != null
        ? widget.imageSize!.width / widget.imageSize!.height
        : _fallbackAspectRatio;

    return AspectRatio(
      key: key,
      aspectRatio: aspectRatio,
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.url,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      cache: true,
      enableLoadState: true,
      handleLoadingProgress: true,
      timeRetry: widget.timeRetry,
      loadStateChanged: (state) {
        final loadState =
            state.extendedImageLoadState == LoadState.loading ||
            state.extendedImageLoadState == LoadState.completed;
        if (loadState) {
          final progress = state.loadingProgress;
          final bytes = progress?.cumulativeBytesLoaded ?? 0;

          final value = computeProgress(bytes);

          if (state.extendedImageLoadState == LoadState.completed) {
            final info = state.extendedImageInfo;
            if (info != null) {
              if (!_isReported) {
                widget.onImageSizeChanged(info.image.width, info.image.height);
                _isReported = true;
              }
            }
          }

          return Stack(
            fit: StackFit.passthrough,
            children: [
              // 图片
              AnimatedOpacity(
                opacity: state.extendedImageLoadState == LoadState.completed
                    ? 1
                    : 0,
                duration: const Duration(milliseconds: 200),
                child: state.completedWidget,
              ),

              // loading
              if (state.extendedImageLoadState != LoadState.completed)
                _buildPlaceholder(
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 3,
                    constraints: BoxConstraints.tight(const Size(28, 28)),
                    backgroundColor: Colors.grey.shade300,
                    color: context.colorScheme.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
            ],
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
