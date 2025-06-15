import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/vertical_list/gesture.dart';
import 'package:haka_comic/views/reader/reader_inherited.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

extension _ReaderContext on BuildContext {
  ReaderInherited get reader => ReaderInherited.of(this, listen: false);
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
  /// 列表控制
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();

  /// 已加载图片索引 - 用于避免重复预加载
  final Set<int> _loadedImages = {};

  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  /// 获取当前漫画ID
  String get cid => context.reader.cid;

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
    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    _initImageSizeCache();

    super.initState();
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);

    _preloadDebounceTimer?.cancel();

    super.dispose();
  }

  /// 翻页
  void jumpOffset(double offset) {
    scrollOffsetController.animateScroll(
      offset: offset,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final physics =
        ScrollPhysicsInherited.of(context) ??
        const AlwaysScrollableScrollPhysics();
    return GestureWrapper(
      jumpOffset: jumpOffset,
      child: ScrollablePositionedList.builder(
        initialScrollIndex: widget.initialIndex ?? 0,
        padding: EdgeInsets.zero,
        physics: physics,
        itemCount: widget.images.length,
        itemScrollController: widget.itemScrollController,
        itemPositionsListener: itemPositionsListener,
        scrollOffsetController: scrollOffsetController,
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
    );
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
      width: width,
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
