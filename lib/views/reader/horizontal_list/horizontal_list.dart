import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/reader_inherited.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
  String get cid => ReaderInherited.of(context, listen: false).cid;

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
    _initImageSizeCache();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.pageController.jumpToPage(widget.initialIndex ?? 0);
      _onItemPositionsChanged(widget.initialIndex ?? 0);
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
    final width = context.width;
    double leftFraction = 0.3;
    double centerFraction = 0.4;

    if (width > 600) {
      leftFraction = 0.2;
      centerFraction = 0.6;
    }

    final leftWidth = width * leftFraction;
    final centerWidth = width * centerFraction;

    return GestureDetector(
      onTapDown: (details) {
        final dx = details.localPosition.dx;
        if (dx < leftWidth) {
          widget.pageController.previousPage(
            duration: const Duration(milliseconds: 250),
            curve: Curves.linear,
          );
        } else if (dx < (leftWidth + centerWidth)) {
          ReaderInherited.of(context, listen: false).openOrCloseToolbar();
        } else {
          widget.pageController.nextPage(
            duration: const Duration(milliseconds: 250),
            curve: Curves.linear,
          );
        }
      },
      child: PhotoViewGallery.builder(
        backgroundDecoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
        ),
        scrollPhysics: const BouncingScrollPhysics(),
        // scrollPhysics: const PageScrollPhysics(),
        itemCount: widget.images.length,
        pageController: widget.pageController,
        onPageChanged: (index) {
          _onItemPositionsChanged(index);
        },
        builder: (context, index) {
          final item = widget.images[index];
          final imageSize = _imageSizeCache[item.uid];

          photoViewControllers[index] ??= PhotoViewController();

          return PhotoViewGalleryPageOptions(
            minScale: PhotoViewComputedScale.contained * 1,
            maxScale: PhotoViewComputedScale.covered * 10,
            controller: photoViewControllers[index],
            imageProvider: CachedNetworkImageProvider(item.media.url),
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: IconButton(
                  onPressed: () async {
                    final provider = CachedNetworkImageProvider(item.media.url);
                    provider.evict();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              );
            },
          );
        },
        loadingBuilder: (context, event) {
          return Center(
            child: CircularProgressIndicator(
              value:
                  event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              strokeWidth: 3,
              constraints: BoxConstraints.tight(const Size(28, 28)),
              backgroundColor: Colors.grey.shade300,
              color: context.colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          );
        },
      ),
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

class HorizontalImage extends StatefulWidget {
  const HorizontalImage({
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
  State<HorizontalImage> createState() => _HorizontalImageState();
}

class _HorizontalImageState extends State<HorizontalImage> {
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
    final height = context.height * 0.6;

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
      width: double.infinity,
      height: double.infinity,
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
