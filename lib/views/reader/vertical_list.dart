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

class _VerticalListState extends State<VerticalList> {
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

  /// 图片尺寸数据数据库
  final _imagesHelper = ImagesHelper();

  /// 防抖计时器 - 用于减少频繁的位置更新回调
  Timer? _debounceTimer;

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
  void _initImageSizeCache() {
    // 一次性查询所有图片尺寸并缓存
    _imagesHelper.query(cid).forEach((imageSize) {
      _imageSizeCache[imageSize.imageId] = imageSize;
    });
  }

  @override
  void initState() {
    if (isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    _initImageSizeCache();

    super.initState();
  }

  @override
  void dispose() {
    if (isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);

    // 取消防抖计时器
    _debounceTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _updatePointerCount(1),
      onPointerUp: (event) => _updatePointerCount(-1),
      onPointerCancel: (event) => _updatePointerCount(-1),
      child: GestureDetector(
        onTap: () => context.reader.openOrCloseToolbar(),
        child: InteractiveViewer(
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

  /// 处理列表项位置变化
  /// 使用防抖减少频繁更新
  void _onItemPositionsChanged() {
    // 取消之前的计时器
    _debounceTimer?.cancel();

    // 设置新的防抖计时器，100ms内只处理最后一次位置变化
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final positions = itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      final visibleIndices =
          positions
              .where(
                (position) =>
                    position.itemTrailingEdge > 0 &&
                    position.itemLeadingEdge < 1,
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
        _preloadImages(firstIndex - 1, firstIndex - 3);
      } else {
        // 向下滚动，预加载下方图片
        _preloadImages(lastIndex + 1, lastIndex + 3);
      }

      _visibleFirstIndex = firstIndex;

      // 通知父组件当前可见的最后一个图片索引
      widget.onItemVisibleChanged(lastIndex);
    });
  }

  /// 预加载指定范围内的图片
  /// 优化：避免重复加载和越界访问
  void _preloadImages(int startIndex, int endIndex) {
    // 确保方向正确
    final start = startIndex < endIndex ? startIndex : endIndex;
    final end = startIndex < endIndex ? endIndex : startIndex;

    for (int i = start; i <= end; i++) {
      // 检查索引是否有效
      if (i < 0 || i >= widget.images.length) continue;
      // 避免重复加载
      if (_loadedImages.contains(i)) continue;

      final imageUrl = widget.images[i].media.url;
      // 使用缓存网络图片提供器预加载
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      precacheImage(imageProvider, context);
      _loadedImages.add(i);
    }
  }

  /// 将图片尺寸信息插入数据库
  /// 使用microtask确保UI不被阻塞
  void _insertImageSize(ImageSize imageSize) {
    Future.microtask(() => _imagesHelper.insert(imageSize));
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
  ImageStream? _currentImageStream;
  ImageStreamListener? _currentListener;

  Future<void> _refreshImage() async {
    final provider = CachedNetworkImageProvider(widget.url);
    await provider.evict();
    setState(() {
      _version++;
    });
  }

  void _removeListener() {
    if (_currentImageStream != null && _currentListener != null) {
      _currentImageStream!.removeListener(_currentListener!);
      _currentImageStream = null;
      _currentListener = null;
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final imageSize = widget.imageSize;
    final width = size.width;
    final height =
        imageSize != null
            ? (imageSize.height * width) / imageSize.width
            : size.height * 0.6;

    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$_version'),
      imageUrl: widget.url,
      fit: BoxFit.fitWidth,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return SizedBox(
          height: height,
          width: width,
          child: Center(
            child: CircularProgressIndicator(
              value: downloadProgress.progress ?? 0,
              strokeWidth: 3,
              constraints: BoxConstraints.tight(const Size(28, 28)),
              backgroundColor: Colors.grey.shade300,
              color: context.colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
        );
      },
      fadeOutDuration: Duration.zero,
      errorWidget:
          (context, url, error) => SizedBox(
            height: height,
            width: width,
            child: Center(
              child: IconButton(
                onPressed: _refreshImage,
                icon: Icon(Icons.refresh),
              ),
            ),
          ),
      imageBuilder: (context, imageProvider) {
        final resolve = imageProvider.resolve(ImageConfiguration.empty);

        if (resolve != _currentImageStream) {
          _removeListener();
          _currentImageStream = resolve;
        }

        if (_currentListener == null) {
          _currentListener = ImageStreamListener((imageInfo, synchronousCall) {
            if (!mounted) return;
            widget.onImageSizeChanged(
              imageInfo.image.width,
              imageInfo.image.height,
            );
            _removeListener();
          });
          _currentImageStream!.addListener(_currentListener!);
        }
        return Image(image: imageProvider);
      },
    );
  }
}
