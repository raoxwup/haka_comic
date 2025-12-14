import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/widgets/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/widgets/vertical_list/gesture.dart';
import 'package:haka_comic/views/reader/widgets/comic_image.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 条漫模式
class VerticalList extends StatefulWidget {
  const VerticalList({super.key});

  @override
  State<VerticalList> createState() => _VerticalListState();
}

class _VerticalListState extends State<VerticalList> with ComicListMixin {
  /// 列表控制
  final itemPositionsListener = ItemPositionsListener.create();

  /// 获取当前漫画ID
  String get cid => context.reader.id;

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
    final physics = context.stateSelector((p) => p.physics);

    final widthRatio = context.stateSelector((p) => p.verticalListWidthRatio);

    final pageCount = context.selector((p) => p.pageCount);

    final images = context.selector((p) => p.images);

    final pageNo = context.selector((p) => p.pageNo);

    return GestureWrapper(
      openOrCloseToolbar: context.reader.openOrCloseToolbar,
      jumpOffset: context.reader.pageTurnForVertical,
      child: FractionallySizedBox(
        widthFactor: widthRatio.clamp(0.0, 1.0),
        child: ScrollablePositionedList.builder(
          initialScrollIndex: pageNo,
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
    int last = visibleIndices.last;

    context.reader.preloadController.onAnchorChanged(last);

    context.reader.onPageNoChanged(
      last.clamp(0, context.reader.images.length - 1),
    );
  }
}
