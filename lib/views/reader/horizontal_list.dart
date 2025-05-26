part of 'reader.dart';

/// 条漫模式
class HorizontalList extends StatefulWidget {
  const HorizontalList({
    super.key,
    required this.images,
    required this.onItemVisibleChanged,
    this.initialIndex,
    required this.pageController,
  });

  /// 漫画图片
  final List<ChapterImage> images;

  /// 图片可见回调
  final ValueChanged<int> onItemVisibleChanged;

  /// 初始索引
  final int? initialIndex;

  final PageController pageController;

  @override
  State<HorizontalList> createState() => _HorizontalListState();
}

class _HorizontalListState extends State<HorizontalList> {
  /// 已加载图片索引 - 用于避免重复预加载
  final Set<int> _loadedImages = {};

  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  final Map<int, PhotoViewController> photoViewControllers = {};

  /// 获取当前章节ID
  String get cid => context.reader.widget.id;

  /// 图片尺寸缓存 - 避免重复查询数据库
  final Map<String, ImageSize> _imageSizeCache = {};

  final scaleStateController = PhotoViewScaleStateController();

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
    _initImageSizeCache();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.reader.readMode == Axis.horizontal) {
        widget.pageController.jumpToPage(widget.initialIndex ?? 0);
        _onItemPositionsChanged(widget.initialIndex ?? 0);
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _preloadDebounceTimer?.cancel();

    for (var controller in photoViewControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGallery.builder(
      backgroundDecoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
      ),
      scrollPhysics: const BouncingScrollPhysics(),
      itemCount: widget.images.length,
      pageController: widget.pageController,
      onPageChanged: (index) {
        _onItemPositionsChanged(index);
      },
      builder: (context, index) {
        final item = widget.images[index];
        final imageSize = _imageSizeCache[item.uid];

        photoViewControllers[index] ??= PhotoViewController();

        return PhotoViewGalleryPageOptions.customChild(
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          controller: photoViewControllers[index],
          child: GestureDetector(
            onTap: () => context.reader.openOrCloseToolbar(),
            child: VerticalImage(
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
            ),
          ),
        );
      },
    );
  }

  // 最大预加载数量限制
  static const int _maxPreloadCount = 4;

  /// 处理列表项位置变化
  void _onItemPositionsChanged(index) {
    // 根据滚动方向预加载不同方向的图片
    if (_visibleFirstIndex > index) {
      // 向上滚动，预加载上方图片
      _preloadImages(index - 1, index - _maxPreloadCount);
    } else {
      // 向下滚动，预加载下方图片
      _preloadImages(index + 1, index + _maxPreloadCount);
    }

    _visibleFirstIndex = index;

    // 通知父组件当前可见的最后一个图片索引
    widget.onItemVisibleChanged(index);
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
