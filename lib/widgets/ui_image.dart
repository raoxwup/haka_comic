import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/router/route_observer.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/retry_for_image.dart';
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
    this.timeRetry = const Duration(milliseconds: 300),
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

  final Duration timeRetry;

  final VoidCallback? onFinally;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final memCacheWidth = ((width ?? cacheWidth) * devicePixelRatio).round();

    final provider = ResizeImage.resizeIfNeeded(
      memCacheWidth,
      cacheHeight,
      CachedNetworkImageProvider(url, cacheManager: cacheManager),
    );

    return _frame(
      context,
      child: RetryForImage(
        imageProvider: provider,
        fadeDuration: const Duration(milliseconds: 250),
        onImageResolved: (_) => onFinally?.call(),
        builder: (context, status) {
          if (status.isLoaded) {
            return Image(
              image: status.provider,
              fit: fit,
              width: width,
              height: height,
              filterQuality: filterQuality,
            );
          }
          if (status.isExhausted) {
            onFinally?.call();
            return Center(
              child: IconButton(
                onPressed: status.retry,
                icon: const Icon(Icons.refresh),
              ),
            );
          }
          return const SizedBox.expand();
        },
      ),
    );
  }

  Widget _frame(BuildContext context, {Widget? child}) {
    final boxShape = shape ?? BoxShape.rectangle;
    return Container(
      width: width,
      height: height,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        shape: boxShape,
        border: border,
        borderRadius: boxShape == BoxShape.circle ? null : borderRadius,
      ),
      child: child,
    );
  }
}

// 同时加载的图片数量
final _imageLoadPool = Pool(6);

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
    this.timeRetry = const Duration(milliseconds: 300),
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

  final Duration timeRetry;

  final Widget? placeholder;

  @override
  State<UiImage> createState() => _UiImageOuterState();
}

class _UiImageOuterState extends State<UiImage> with RouteAware {
  PoolResource? _resource;
  bool _ready = false;
  bool _isDisposed = false;
  bool _isAcquiring = false;

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
    if (!_ready && _resource == null) {
      _acquire();
    }
  }

  Future<void> _acquire() async {
    if (_ready || _resource != null || _isAcquiring || _isDisposed) return;

    _isAcquiring = true;
    final resource = await _imageLoadPool.request();
    _isAcquiring = false;

    if (!mounted || _isDisposed || _ready || _resource != null) {
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
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : widget.borderRadius,
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
      timeRetry: widget.timeRetry,
      onFinally: _onImageLoadFinally,
    );
  }
}
