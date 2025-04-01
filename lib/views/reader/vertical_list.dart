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

  /// 已加载图片索引
  final Set<int> _loadedImages = {};

  /// 可见的第一项图片索引
  int _visibleFirstIndex = 0;

  /// 图片尺寸数据
  final _imagesHelper = ImagesHelper();

  bool _handleKeyEvent(KeyEvent event) {
    if (!isDesktop) return false;
    final key = event.logicalKey;
    final isControl =
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;

    if (event is KeyDownEvent && isControl) {
      setState(() {
        _isCtrlPressed = true;
        _listPhysics = const NeverScrollableScrollPhysics();
      });
    } else if (event is KeyUpEvent && isControl) {
      setState(() {
        _isCtrlPressed = false;
        _listPhysics = const AlwaysScrollableScrollPhysics();
      });
    }

    return false;
  }

  String get cid => context.reader.widget.id;

  @override
  void initState() {
    if (isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    super.initState();
  }

  @override
  void dispose() {
    if (isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);

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
              final imageSize = _imagesHelper.find(cid, item.uid);
              return VerticalImage(
                url: item.media.url,
                onImageSizeChanged:
                    (width, height) => _insertImageSize(
                      ImageSize(
                        width: width,
                        height: height,
                        imageId: item.uid,
                        cid: cid,
                      ),
                    ),
                imageSize: imageSize,
              );
            },
          ),
        ),
      ),
    );
  }

  void _updatePointerCount(int delta) {
    final newCount = _activePointers + delta;
    final clampedCount = newCount.clamp(0, double.maxFinite.toInt());

    if (clampedCount == _activePointers) return;

    final newPhysics =
        clampedCount >= 2
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics();

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

  void _onItemPositionsChanged() {
    final positions = itemPositionsListener.itemPositions.value;
    final visibleIndices =
        positions
            .where(
              (position) =>
                  position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
            )
            .map((position) => position.index)
            .toList();
    visibleIndices.sort();
    int lastIndex = visibleIndices.last;
    int firstIndex = visibleIndices.first;
    if (_visibleFirstIndex > lastIndex) {
      _preloadImages(firstIndex - 1, firstIndex - 3); // 上翻
    } else {
      _preloadImages(lastIndex + 1, lastIndex + 3); // 下翻
    }

    _visibleFirstIndex = firstIndex;

    widget.onItemVisibleChanged(lastIndex);
  }

  /// 预加载
  void _preloadImages(int startIndex, int endIndex) {
    for (int i = startIndex; i <= endIndex; i++) {
      if (i < 0 || i >= widget.images.length) continue;
      if (_loadedImages.contains(i)) continue;
      final imageUrl = widget.images[i].media.url;
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      precacheImage(imageProvider, context);
      _loadedImages.add(i);
    }
  }

  // 图片宽高回调
  void _insertImageSize(ImageSize imageSize) {
    _imagesHelper.insert(imageSize);
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
  final Function(double, double) onImageSizeChanged;

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
              imageInfo.image.width.toDouble(),
              imageInfo.image.height.toDouble(),
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
