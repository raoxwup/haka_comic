import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/views/reader/reader_provider.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/gesture.dart';
import 'package:haka_comic/views/reader/widget/comic_image.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 条漫模式
class VerticalList extends StatefulWidget {
  const VerticalList({super.key});

  @override
  State<VerticalList> createState() => _VerticalListState();
}

class _VerticalListState extends State<VerticalList> with ComicListMixin {
  /// 列表控制
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  /// 获取当前漫画ID
  String get cid => context.reader.cid;

  /// 图片尺寸缓存 - 避免重复查询数据库
  final Map<String, ImageSize> _imageSizeCache = {};

  /// 初始化图片尺寸缓存
  Future<void> _initImageSizeCache() async {
    final sizes = await ImagesHelper().query(cid);
    for (var imageSize in sizes) {
      _imageSizeCache[imageSize.imageId] = imageSize;
    }
  }

  @override
  void initState() {
    super.initState();

    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    _initImageSizeCache();
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final physics =
        ScrollPhysicsInherited.of(context) ?? const BouncingScrollPhysics();

    final verticalListWidth = context.select<ReaderProvider, double>(
      (value) => value.verticalListWidth,
    );

    final pageCount = context.select<ReaderProvider, int>(
      (value) => value.pageCount,
    );

    final images = context.select<ReaderProvider, List<ChapterImage>>(
      (value) => value.images,
    );

    return GestureWrapper(
      openOrCloseToolbar: context.reader.openOrCloseToolbar,
      jumpOffset: context.reader.pageTurnForVertical,
      child: FractionallySizedBox(
        widthFactor: verticalListWidth.clamp(0.0, 1.0),
        child: ScrollablePositionedList.builder(
          initialScrollIndex: context.reader.pageNo,
          padding: EdgeInsets.zero,
          physics: physics,
          itemCount: pageCount + 1,
          itemScrollController: context.reader.itemScrollController,
          itemPositionsListener: itemPositionsListener,
          scrollOffsetController: context.reader.scrollOffsetController,
          itemBuilder: (context, index) {
            if (index == pageCount) {
              return const Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
                child: Text(
                  '本章完',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              );
            }
            final item = images[index];
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
      ),
    );
  }

  /// 处理列表项位置变化
  void _onItemPositionsChanged() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visibleIndices = positions
        .where(
          (pos) => pos.itemTrailingEdge > 0.0 && pos.itemTrailingEdge <= 1.0,
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
        context.reader.images,
      );
    } else {
      // 向下滚动，预加载下方图片
      preloadImages(
        lastIndex + 1,
        lastIndex + maxPreloadCount,
        context.reader.images,
      );
    }

    _visibleFirstIndex = firstIndex;

    context.reader.onPageNoChanged(
      lastIndex.clamp(0, context.reader.images.length - 1),
    );
  }
}
