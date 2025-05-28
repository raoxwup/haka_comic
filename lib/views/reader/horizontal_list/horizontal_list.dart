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

  final Map<String, PhotoViewController> photoViewControllers = {};

  /// 获取当前章节ID
  String get cid => ReaderInherited.of(context, listen: false).cid;

  @override
  void initState() {
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

  TapDownDetails? _tapDetails;

  void _handleTap() {
    if (_tapDetails == null) return;
    final width = context.width;
    double leftFraction = 0.3;
    double centerFraction = 0.4;

    if (width > 600) {
      leftFraction = 0.2;
      centerFraction = 0.6;
    }

    final leftWidth = width * leftFraction;
    final centerWidth = width * centerFraction;

    final dx = _tapDetails!.localPosition.dx;
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _tapDetails = details;
      },
      onTap: _handleTap,
      child: PhotoViewGallery.builder(
        backgroundDecoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
        ),
        scrollPhysics: const BouncingScrollPhysics(),
        itemCount: widget.images.length,
        pageController: widget.pageController,
        onPageChanged: _onItemPositionsChanged,
        builder: (context, index) {
          final item = widget.images[index];

          photoViewControllers[item.uid] ??= PhotoViewController();

          return PhotoViewGalleryPageOptions(
            minScale: PhotoViewComputedScale.contained * 1,
            maxScale: PhotoViewComputedScale.covered * 4,
            controller: photoViewControllers[item.uid],
            imageProvider: CachedNetworkImageProvider(item.media.url),
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace, retry) {
              return Center(
                child: IconButton(
                  onPressed: () async {
                    final provider = CachedNetworkImageProvider(item.media.url);
                    provider.evict();
                    retry();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              );
            },
            onImageFrame: (info, synchronousCall) {
              final imageSize = ImageSize(
                imageId: item.uid,
                width: info.image.width,
                height: info.image.height,
                cid: cid,
              );
              _insertImageSize(imageSize);
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
