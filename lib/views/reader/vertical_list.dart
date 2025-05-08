part of 'reader.dart';

extension _ReaderContext on BuildContext {
  _ReaderState get reader => findAncestorStateOfType<_ReaderState>()!;
}

/// 条漫模式
class VerticalList extends StatefulWidget {
  const VerticalList({
    super.key,
    required this.images,
    required this.onItemVisibleChanged,
    this.initialIndex,
    required this.itemScrollController,
  });

  /// 漫画图片
  final List<ChapterImage> images;

  /// 图片可见回调
  final ValueChanged<int> onItemVisibleChanged;

  /// 初始索引
  final int? initialIndex;

  final ItemScrollController itemScrollController;

  @override
  State<VerticalList> createState() => _VerticalListState();
}

class _VerticalListState extends State<VerticalList>
    with SingleTickerProviderStateMixin {
  /// ctrl是否点击
  bool _isCtrlPressed = false;

  /// 当前触摸点个数
  int _activePointers = 0;

  /// 滑动控制
  ScrollPhysics _listPhysics = const AlwaysScrollableScrollPhysics();

  /// 列表控制
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// 已加载图片索引 - 用于避免重复预加载
  final Set<int> _loadedImages = {};

  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  ///双击缩放相关
  final TransformationController _transformationController =
      TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  /// 处理键盘事件
  /// 返回false允许事件继续传播
  bool _handleKeyEvent(KeyEvent event) {
    if (!isDesktop) return false;
    final key = event.logicalKey;
    final isControl =
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;

    // 优化：避免不必要的setState调用
    if (event is KeyDownEvent && isControl) {
      if (!_isCtrlPressed) {
        setState(() {
          _isCtrlPressed = true;
          _listPhysics = const NeverScrollableScrollPhysics();
        });
      }
    } else if (event is KeyUpEvent && isControl) {
      if (_isCtrlPressed) {
        setState(() {
          _isCtrlPressed = false;
          _listPhysics = const AlwaysScrollableScrollPhysics();
        });
      }
    }

    return false;
  }

  /// 获取当前章节ID
  String get cid => context.reader.widget.id;

  /// 图片尺寸缓存 - 避免重复查询数据库
  final Map<String, ImageSize> _imageSizeCache = {};

  /// 初始化图片尺寸缓存
  Future<void> _initImageSizeCache() async {
    // 一次性查询所有图片尺寸并缓存
    final sizes = await ImagesHelper.query(cid);
    for (var imageSize in sizes) {
      _imageSizeCache[imageSize.imageId] = imageSize;
    }
  }

  @override
  void initState() {
    if (isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    _initImageSizeCache();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
      _transformationController.value = _animation.value;
    });

    super.initState();
  }

  @override
  void dispose() {
    if (isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);

    _preloadDebounceTimer?.cancel();

    _transformationController.dispose();

    _animationController.dispose();

    super.dispose();
  }

  /// 双击放大/恢复
  void _handleDoubleTap() {
    Matrix4 endMatrix;
    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix =
          Matrix4.identity()
            ..translate(
              -_doubleTapPosition.dx * 2.0,
              -_doubleTapPosition.dy * 2.0,
            )
            ..scale(3.0);
    }
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController));
    _animationController.forward(from: 0);
  }

  /// 获取双击位置
  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _updatePointerCount(1),
      onPointerUp: (event) => _updatePointerCount(-1),
      onPointerCancel: (event) => _updatePointerCount(-1),
      child: GestureDetector(
        onTap: () => context.reader.openOrCloseToolbar(),
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          scaleEnabled: isDesktop ? _isCtrlPressed : true,
          minScale: 1,
          maxScale: 3.5,
          child: ScrollablePositionedList.builder(
            initialScrollIndex: widget.initialIndex ?? 0,
            padding: EdgeInsets.zero,
            physics: _listPhysics,
            itemCount: widget.images.length,
            itemScrollController: widget.itemScrollController,
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (context, index) {
              final item = widget.images[index];
              final imageSize = _imageSizeCache[item.uid];
              return VerticalImage(
                url: item.media.url,
                onImageSizeChanged: (width, height) {
                  final size = ImageSize(
                    width: width,
                    height: height,
                    imageId: item.uid,
                    cid: cid,
                  );
                  _insertImageSize(size);
                  _imageSizeCache[item.uid] = size;
                },
                imageSize: imageSize,
              );
            },
          ),
        ),
      ),
    );
  }

  /// 更新触摸点数量并相应地更新滚动物理效果
  void _updatePointerCount(int delta) {
    final newCount = _activePointers + delta;
    // 确保计数不会为负
    final clampedCount = newCount.clamp(0, double.maxFinite.toInt());

    if (clampedCount == _activePointers) return;

    final newPhysics =
        clampedCount >= 2
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics();

    // 优化：只在物理效果类型变化时才调用setState
    if (newPhysics.runtimeType != _listPhysics.runtimeType) {
      setState(() {
        _activePointers = clampedCount;
        _listPhysics = newPhysics;
      });
    } else {
      // 仅更新内部状态不触发重建
      _activePointers = clampedCount;
    }
  }

  // 最大预加载数量限制
  static const int _maxPreloadCount = 4;

  /// 处理列表项位置变化
  void _onItemPositionsChanged() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visibleIndices =
        positions
            .where(
              (position) =>
                  position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
            )
            .map((position) => position.index)
            .toList();

    if (visibleIndices.isEmpty) return;

    visibleIndices.sort();
    int lastIndex = visibleIndices.last;
    int firstIndex = visibleIndices.first;

    // 根据滚动方向预加载不同方向的图片
    if (_visibleFirstIndex > lastIndex) {
      // 向上滚动，预加载上方图片
      _preloadImages(firstIndex - 1, firstIndex - _maxPreloadCount);
    } else {
      // 向下滚动，预加载下方图片
      _preloadImages(lastIndex + 1, lastIndex + _maxPreloadCount);
    }

    _visibleFirstIndex = firstIndex;

    // 通知父组件当前可见的最后一个图片索引
    widget.onItemVisibleChanged(lastIndex);
  }

  /// 预加载指定范围内的图片
  /// 优化：避免重复加载和越界访问
  // 用于控制预加载频率的计时器
  Timer? _preloadDebounceTimer;

  void _preloadImages(int startIndex, int endIndex) {
    // 取消之前的预加载计时器
    _preloadDebounceTimer?.cancel();

    // 设置新的防抖计时器，50ms内只处理最后一次预加载请求
    _preloadDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      // 确保方向正确
      final start = startIndex < endIndex ? startIndex : endIndex;
      final end = startIndex < endIndex ? endIndex : startIndex;

      for (int i = start; i <= end; i++) {
        // 检查索引是否有效
        if (i < 0 || i >= widget.images.length) continue;
        // 避免重复加载
        if (_loadedImages.contains(i)) continue;

        final imageUrl = widget.images[i].media.url;
        final imageProvider = CachedNetworkImageProvider(imageUrl);
        precacheImage(imageProvider, context);
        _loadedImages.add(i);
      }
    });
  }

  /// 将图片尺寸信息插入数据库
  void _insertImageSize(ImageSize imageSize) {
    ImagesHelper.insert(imageSize);
  }
}

class VerticalImage extends StatefulWidget {
  const VerticalImage({
    super.key,
    required this.url,
    required this.onImageSizeChanged,
    this.imageSize,
  });

  /// 图片url
  final String url;

  /// 图片尺寸回调
  final Function(int, int) onImageSizeChanged;

  /// 缓存的图片尺寸
  final ImageSize? imageSize;

  @override
  State<VerticalImage> createState() => _VerticalImageState();
}

class _VerticalImageState extends State<VerticalImage> {
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
    // 计算图片高度，优先使用缓存的尺寸
    final width = context.width;
    final height =
        widget.imageSize != null
            ? (widget.imageSize!.height * width) / widget.imageSize!.width
            : context.height * 0.6;

    // 创建占位容器，避免重复代码
    Widget createPlaceholder({required Widget child}) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(child: child),
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$_version'),
      imageUrl: widget.url,
      fit: BoxFit.fitWidth,
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
