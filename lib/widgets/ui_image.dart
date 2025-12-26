import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/router/route_observer.dart';
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
          return Container(
            color: context.colorScheme.surfaceContainerHigh,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(state.extendedImageInfo),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuad,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: state.completedWidget,
            ),
          );
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
final _imageLoadPool = Pool(5);

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

class _UiImageState extends State<UiImage> with RouteAware {
  PoolResource? _resource;
  bool _ready = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _acquire();
  }

  // 订阅路由监听
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _isDisposed = true;
    _releaseCurrentResource();
    super.dispose();
  }

  @override
  void didPushNext() {
    _releaseCurrentResource();
  }

  @override
  void didPopNext() {
    if (_resource == null) {
      // setState(() => _ready = false);
      _acquire();
    }
  }

  Future<void> _acquire() async {
    if (_resource != null) return;

    final resource = await _imageLoadPool.request();

    if (!mounted || _isDisposed) {
      resource.release();
      return;
    }

    // 双重保险：检查当前页面是否可见
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      resource.release();
      return;
    }

    _resource = resource;
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void _releaseCurrentResource() {
    final target = _resource;
    _resource = null;
    target?.release();
  }

  void _onImageLoadFinally() {
    if (_isDisposed) return;
    _releaseCurrentResource();
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
      onFinally: _onImageLoadFinally,
    );
  }
}
