import 'dart:io';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';
import 'package:haka_comic/widgets/retry_for_image.dart';

class ReaderImage extends StatefulWidget {
  const ReaderImage({
    super.key,
    required this.url,
    this.cacheKey,
    this.imageSize,
    this.enableCache = true,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.cacheWidth,
    this.timeRetry = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    required this.onImageSizeChanged,
  });

  // 图片url 或 本地文件路径
  final String url;

  final String? cacheKey;

  // 缓存的图片尺寸
  final ImageSize? imageSize;
  final BoxFit fit;

  // 是否使用缓存的尺寸
  final bool enableCache;
  final FilterQuality filterQuality;
  final int? cacheWidth;
  final Duration timeRetry;
  final AlignmentGeometry alignment;

  // 尺寸回调
  final void Function(int width, int height) onImageSizeChanged;

  @override
  State<ReaderImage> createState() => _ReaderImageState();
}

class _ReaderImageState extends State<ReaderImage> {
  static const double _fallbackAspectRatio = 3 / 4;

  bool get isNetwork {
    final scheme = Uri.tryParse(widget.url)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  ImageProvider _buildProvider() {
    final ImageProvider base = isNetwork
        ? CachedNetworkImageProvider(
            widget.url,
            cacheManager: cacheManager,
            cacheKey: widget.cacheKey,
          )
        : FileImage(File(widget.url));
    return ResizeImage.resizeIfNeeded(widget.cacheWidth, null, base);
  }

  double get _placeholderAspectRatio {
    final size = widget.imageSize;
    if (size == null || size.width <= 0 || size.height <= 0) {
      return _fallbackAspectRatio;
    }
    return size.width / size.height;
  }

  Widget _buildPlaceholder(Widget child) {
    if (!widget.enableCache) {
      return Center(child: child);
    }
    return AspectRatio(
      aspectRatio: _placeholderAspectRatio,
      child: Center(child: child),
    );
  }

  Widget _buildProgressIndicator(double? value) {
    return _buildPlaceholder(
      CircularProgressIndicator(
        value: value ?? 0.0,
        strokeWidth: 3,
        constraints: BoxConstraints.tight(const Size(28, 28)),
        backgroundColor: Colors.grey.shade300,
        color: context.colorScheme.primary,
        strokeCap: StrokeCap.round,
      ),
    );
  }

  double? _progressValue(ImageChunkEvent? chunk) {
    if (chunk == null) return null;
    final total = chunk.expectedTotalBytes;
    final loaded = chunk.cumulativeBytesLoaded;
    if (total != null && total > 0) {
      return (loaded / total).clamp(0.0, 1.0);
    }
    return computeProgress(loaded);
  }

  @override
  Widget build(BuildContext context) {
    return RetryForImage(
      imageProvider: _buildProvider(),
      retryDelay: widget.timeRetry,
      fadeDuration: const Duration(milliseconds: 200),
      onImageResolved: (info) {
        widget.onImageSizeChanged(info.image.width, info.image.height);
      },
      builder: (context, status) {
        if (status.isLoaded) {
          return Image(
            image: status.provider,
            fit: widget.fit,
            filterQuality: widget.filterQuality,
            alignment: widget.alignment,
          );
        }
        if (status.isExhausted) {
          return _buildPlaceholder(
            IconButton(
              onPressed: status.retry,
              icon: const Icon(Icons.refresh),
            ),
          );
        }
        return _buildProgressIndicator(_progressValue(status.chunk));
      },
    );
  }
}
