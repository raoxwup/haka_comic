import 'dart:async';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/widgets.dart';

final cacheManager = DefaultCacheManager(
  stalePeriod: const Duration(days: 15),
  maxNrOfCacheObjects: 2000,
);

/// 当前 [RetryForImage] 订阅的图片状态快照，传给 [RetryForImageBuilder]。
class RetryImageStatus {
  const RetryImageStatus({
    required this.provider,
    required this.attempt,
    required this.maxAttempts,
    required this.isLoaded,
    required this.retry,
    this.chunk,
    this.error,
  });

  /// 当前正在加载的 [ImageProvider]。builder 渲染实际图片时直接用它即可。
  final ImageProvider provider;

  /// 当前尝试次数（0 = 首次加载，N = 第 N 次自动重试）。
  final int attempt;

  /// 允许的最大自动重试次数。
  final int maxAttempts;

  /// 是否已经有至少一次解码成功（出现过 [ImageInfo]）。
  final bool isLoaded;

  /// 最近一次下载进度事件，加载成功后会被清空。仅网络图会有值。
  final ImageChunkEvent? chunk;

  /// 最近一次错误；成功或新一轮重试开始后会被清空。
  final Object? error;

  /// 手动重试。调用后计数器归零，并重新拉取图片。
  final VoidCallback retry;

  /// 处于自动重试过程中（有错误但还有自动重试余量）。
  bool get isRetrying => error != null && attempt < maxAttempts;

  /// 自动重试已耗尽，等待用户手动点击重试。
  bool get isExhausted => error != null && attempt >= maxAttempts;
}

typedef RetryForImageBuilder =
    Widget Function(BuildContext context, RetryImageStatus status);

/// 一个只负责重试逻辑的图片包装组件。
///
/// - 直接订阅 [imageProvider]，内部监听加载错误、下载进度和解码完成。
/// - 出错时按 [retryDelay] 定时自动重试，累计 [maxAttempts] 次仍失败后停手，
///   交由用户通过 [RetryImageStatus.retry] 手动重置。
/// - 视觉表现完全由 [builder] 决定；builder 可以根据 status 选择渲染占位、
///   进度圈、错误按钮或实际图片。
class RetryForImage extends StatefulWidget {
  const RetryForImage({
    super.key,
    required this.imageProvider,
    required this.builder,
    this.maxAttempts = 3,
    this.retryDelay = const Duration(milliseconds: 200),
    this.fadeDuration = const Duration(milliseconds: 250),
    this.fadeCurve = Curves.easeOutQuad,
    this.onImageResolved,
  });

  /// 待加载的图片 provider。当这个值（按 `==` 比较）发生变化时，内部会
  /// 解除旧订阅、清零计数器并重新订阅新 provider。
  final ImageProvider imageProvider;

  /// 使用当前状态构建图片 UI。
  final RetryForImageBuilder builder;

  /// 最多自动重试多少次。
  final int maxAttempts;

  /// 收到错误后延迟多久触发下一次自动重试。
  final Duration retryDelay;

  /// 在 loading / loaded / exhausted 三种状态之间切换时的淡入淡出时长。
  /// 首次 build 即处于 loaded（命中缓存）时不会触发动画。
  /// 设为 [Duration.zero] 可关闭动画。
  final Duration fadeDuration;

  /// 状态切换时使用的缓动曲线。
  final Curve fadeCurve;

  /// 每轮加载首次解码成功时触发，用于把 [ImageInfo]（含宽高）暴露给调用方。
  final void Function(ImageInfo info)? onImageResolved;

  @override
  State<RetryForImage> createState() => _RetryForImageState();
}

class _RetryForImageState extends State<RetryForImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;

  int _attempt = 0;
  bool _isLoaded = false;
  bool _resolvedFired = false;
  ImageChunkEvent? _chunk;
  Object? _error;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首次订阅放到这里，确保 InheritedWidget（ImageConfiguration 会用到）
    // 已经就绪。
    if (_listener == null) {
      _subscribe();
    }
  }

  @override
  void didUpdateWidget(covariant RetryForImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _resetForNewProvider();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _unsubscribe();
    super.dispose();
  }

  // ---------- 订阅管理 ----------

  void _subscribe() {
    final config = createLocalImageConfiguration(context);
    final stream = widget.imageProvider.resolve(config);
    final listener = ImageStreamListener(
      _handleImage,
      onChunk: _handleChunk,
      onError: _handleError,
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _unsubscribe() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  void _resetForNewProvider() {
    _retryTimer?.cancel();
    _unsubscribe();
    _attempt = 0;
    _isLoaded = false;
    _resolvedFired = false;
    _chunk = null;
    _error = null;
  }

  // ---------- 事件回调 ----------

  void _handleImage(ImageInfo info, bool synchronousCall) {
    if (!mounted) return;
    final firstResolve = !_resolvedFired;
    _resolvedFired = true;
    setState(() {
      _isLoaded = true;
      _error = null;
      _chunk = null;
    });
    if (firstResolve) {
      widget.onImageResolved?.call(info);
    }
  }

  void _handleChunk(ImageChunkEvent event) {
    if (!mounted) return;
    setState(() => _chunk = event);
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    if (!mounted) return;
    final shouldSchedule =
        _attempt < widget.maxAttempts && _retryTimer?.isActive != true;
    setState(() {
      _error = error;
      _chunk = null;
      if (shouldSchedule) _attempt++;
    });
    if (shouldSchedule) {
      _retryTimer = Timer(widget.retryDelay, _performRetry);
    }
  }

  // ---------- 重试 ----------

  Future<void> _performRetry() async {
    if (!mounted) return;
    _unsubscribe();
    setState(() {
      _error = null;
      _chunk = null;
    });
    await widget.imageProvider.evict();
    if (!mounted) return;
    _subscribe();
  }

  Future<void> _manualRetry() async {
    _retryTimer?.cancel();
    _unsubscribe();
    setState(() {
      _attempt = 0;
      _isLoaded = false;
      _resolvedFired = false;
      _error = null;
      _chunk = null;
    });
    await widget.imageProvider.evict();
    if (!mounted) return;
    _subscribe();
  }

  /// 当前所处的渲染阶段，用于驱动 AnimatedSwitcher 的过渡。
  _RetryPhase get _phase {
    if (_isLoaded) return _RetryPhase.loaded;
    if (_error != null && _attempt >= widget.maxAttempts) {
      return _RetryPhase.exhausted;
    }
    return _RetryPhase.loading;
  }

  @override
  Widget build(BuildContext context) {
    final status = RetryImageStatus(
      provider: widget.imageProvider,
      attempt: _attempt,
      maxAttempts: widget.maxAttempts,
      isLoaded: _isLoaded,
      chunk: _chunk,
      error: _error,
      retry: _manualRetry,
    );

    final child = KeyedSubtree(
      key: ValueKey(_phase),
      child: widget.builder(context, status),
    );

    if (widget.fadeDuration == Duration.zero) {
      return child;
    }

    return AnimatedSwitcher(
      duration: widget.fadeDuration,
      switchInCurve: widget.fadeCurve,
      switchOutCurve: widget.fadeCurve,
      // 用 passthrough 的 Stack 作为容器，保证外层约束（BoxFit.cover 等
      // 依赖的 tight 约束）能透传给每一个子节点，避免子 Image 因拿到
      // loose 约束而收缩成 intrinsic 尺寸。
      layoutBuilder: _passthroughLayoutBuilder,
      child: child,
    );
  }

  static Widget _passthroughLayoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: <Widget>[...previousChildren, ?currentChild],
    );
  }
}

enum _RetryPhase { loading, loaded, exhausted }
