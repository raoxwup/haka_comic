import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/utils/extension.dart';

class ComicImage extends StatefulWidget {
  const ComicImage({
    super.key,
    required this.url,
    required this.onImageSizeChanged,
    this.imageSize,
    this.fit = BoxFit.fitWidth,
  }) : useCacheSize = true;

  const ComicImage.noUseCache({
    super.key,
    required this.url,
    required this.onImageSizeChanged,
    this.fit = BoxFit.contain,
  }) : useCacheSize = false,
       imageSize = null;

  /// 图片url
  final String url;

  /// 图片尺寸回调
  final Function(int, int) onImageSizeChanged;

  /// 缓存的图片尺寸
  final ImageSize? imageSize;

  /// 是否需要使用缓存的图片尺寸，只有条漫模式需要
  final bool useCacheSize;

  /// 图片fit
  final BoxFit fit;

  @override
  State<ComicImage> createState() => _ComicImageState();
}

class _ComicImageState extends State<ComicImage> {
  int _version = 0;
  ImageStream? _imageStream;
  ImageStreamListener? _listener;

  /// 刷新图片，清除缓存并重新加载
  Future<void> _refreshImage() async {
    final provider = CachedNetworkImageProvider(widget.url);
    await provider.evict();
    if (mounted) {
      setState(() => _version++);
    }
  }

  /// 移除图片流监听器
  void _removeListener() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
      _imageStream = null;
      _listener = null;
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 创建占位容器
    Widget createPlaceholder({required Widget child}) {
      if (!widget.useCacheSize) return Center(child: child);
      final width = context.width;
      final height =
          widget.imageSize != null
              ? (widget.imageSize!.height * width) / widget.imageSize!.width
              : context.height * 0.6;
      return SizedBox(
        height: height,
        width: width,
        child: Center(child: child),
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$_version'),
      imageUrl: widget.url,
      fit: widget.fit,
      fadeOutDuration: Duration.zero,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return createPlaceholder(
          child: CircularProgressIndicator(
            value: downloadProgress.progress ?? 0,
            strokeWidth: 3,
            constraints: BoxConstraints.tight(const Size(28, 28)),
            backgroundColor: Colors.grey.shade300,
            color: context.colorScheme.primary,
            strokeCap: StrokeCap.round,
          ),
        );
      },
      errorWidget:
          (context, url, error) => createPlaceholder(
            child: IconButton(
              onPressed: _refreshImage,
              icon: const Icon(Icons.refresh),
            ),
          ),
      imageBuilder: (context, imageProvider) {
        final resolve = imageProvider.resolve(const ImageConfiguration());

        // 只在图片流变化时更新监听器
        if (resolve != _imageStream) {
          _removeListener();
          _imageStream = resolve;

          _listener = ImageStreamListener((imageInfo, _) {
            if (!mounted) return;
            widget.onImageSizeChanged(
              imageInfo.image.width,
              imageInfo.image.height,
            );
            // 获取尺寸后移除监听器，避免内存泄漏
            _removeListener();
          });

          _imageStream!.addListener(_listener!);
        }

        return Image(image: imageProvider);
      },
    );
  }
}
