import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:pool/pool.dart';

class _UiImage extends StatelessWidget {
  const _UiImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth = 300,
    this.cacheHeight,
    this.shape,
    this.border,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.filterQuality = FilterQuality.low,
    this.onFinally,
  });

  final String url;

  final BoxFit fit;

  final double? width;

  final double? height;

  final int cacheWidth;

  final int? cacheHeight;

  final BoxShape? shape;

  final BoxBorder? border;

  final BorderRadius? borderRadius;

  final Clip clipBehavior;

  final FilterQuality filterQuality;

  final VoidCallback? onFinally;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return ExtendedImage.network(
      url,
      cache: true,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: ((width ?? cacheWidth) * devicePixelRatio).round(),
      cacheHeight: cacheHeight,
      shape: shape,
      border: border,
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      timeRetry: const Duration(milliseconds: 300),
      filterQuality: filterQuality,
      loadStateChanged: (state) {
        final loadState = state.extendedImageLoadState;

        if (loadState == LoadState.completed || loadState == LoadState.failed) {
          onFinally?.call();
        }

        if (loadState == LoadState.failed) {
          return Container(
            color: context.colorScheme.surfaceContainerHigh,
            child: Center(
              child: IconButton(
                onPressed: state.reLoadImage,
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        if (loadState == LoadState.completed) {
          return null;
        }

        if (loadState == LoadState.loading) {
          return Container(color: context.colorScheme.surfaceContainerHigh);
        }

        return null;
      },
    );
  }
}

// 同时加载的图片数量
final _imageLoadPool = Pool(3);

class UiImage extends StatefulWidget {
  const UiImage({
    super.key,
    this.placeholder,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth = 300,
    this.cacheHeight,
    this.shape,
    this.border,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.filterQuality = FilterQuality.low,
  });

  final String url;

  final BoxFit fit;

  final double? width;

  final double? height;

  final int cacheWidth;

  final int? cacheHeight;

  final BoxShape? shape;

  final BoxBorder? border;

  final BorderRadius? borderRadius;

  final Clip clipBehavior;

  final FilterQuality filterQuality;

  final Widget? placeholder;

  @override
  State<UiImage> createState() => _UiImageState();
}

class _UiImageState extends State<UiImage> {
  PoolResource? _resource;
  bool _ready = false;
  bool _released = false;

  @override
  void initState() {
    super.initState();
    _acquire();
  }

  Future<void> _acquire() async {
    final resource = await _imageLoadPool.request();
    if (!mounted) {
      // 确保资源一定能够被释放
      resource.release();
      return;
    }
    _resource = resource;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _safeRelease();
    super.dispose();
  }

  void _safeRelease() {
    if (_released) return;
    _released = true;
    _resource?.release();
    _resource = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.placeholder ??
          Container(
            clipBehavior: widget.clipBehavior,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHigh,
              borderRadius: widget.borderRadius,
              shape: widget.shape ?? BoxShape.rectangle,
              border: widget.border,
            ),
          );
    }
    return _UiImage(
      url: widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      shape: widget.shape,
      border: widget.border,
      borderRadius: widget.borderRadius,
      clipBehavior: widget.clipBehavior,
      filterQuality: widget.filterQuality,
      onFinally: _safeRelease,
    );
  }
}
