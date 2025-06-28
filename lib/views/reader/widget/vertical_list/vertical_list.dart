import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/gesture.dart';
import 'package:haka_comic/views/reader/reader_inherited.dart';
import 'package:haka_comic/views/reader/widget/comic_image.dart';
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

class _VerticalListState extends State<VerticalList> with ComicListMixin {
  /// 列表控制
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();

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
          return ComicImage(
            url: item.media.url,
            onImageSizeChanged: (width, height) {
              final size = ImageSize(
                width: width,
                height: height,
                imageId: item.uid,
                cid: cid,
              );
              insertImageSize(size);
              _imageSizeCache[item.uid] = size;
            },
            imageSize: imageSize,
          );
        },
      ),
    );
  }

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
      preloadImages(
        firstIndex - 1,
        firstIndex - maxPreloadCount,
        widget.images,
      );
    } else {
      // 向下滚动，预加载下方图片
      preloadImages(lastIndex + 1, lastIndex + maxPreloadCount, widget.images);
    }

    _visibleFirstIndex = firstIndex;

    // 通知父组件当前可见的最后一个图片索引
    widget.onItemVisibleChanged(lastIndex);
  }
}
