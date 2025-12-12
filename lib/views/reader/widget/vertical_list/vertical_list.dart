import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/controller_provider.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/providers/toolbar_provider.dart';
import 'package:haka_comic/views/reader/widget/vertical_list/gesture.dart';
import 'package:haka_comic/views/reader/widget/comic_image.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 条漫模式
class VerticalList extends ConsumerStatefulWidget {
  const VerticalList({super.key});

  @override
  ConsumerState<VerticalList> createState() => _VerticalListState();
}

class _VerticalListState extends ConsumerState<VerticalList>
    with ComicListMixin {
  /// 列表控制
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  /// 获取当前漫画ID
  String get cid => ref.watch(
    comicReaderStateProvider(routerPayloadCache).select((p) => p.id),
  );

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

    final verticalListWidth = ref.watch(
      listStateProvider.select((p) => p.verticalListWidthRatio),
    );

    final pageCount = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((p) => p.correctPageCount),
    );

    final images = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((p) => p.images),
    );

    final pageNo = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((p) => p.correctPageNo),
    );

    final toolbarNotifier = ref.read(toolbarProvider.notifier);

    final controllers = ref.read(listControllersProvider);

    return GestureWrapper(
      openOrCloseToolbar: toolbarNotifier.openOrCloseToolbar,
      jumpOffset: ref
          .watch(listControllersProvider.notifier)
          .pageTurnForVertical,
      child: FractionallySizedBox(
        widthFactor: verticalListWidth.clamp(0.0, 1.0),
        child: ScrollablePositionedList.builder(
          initialScrollIndex: pageNo,
          padding: EdgeInsets.zero,
          physics: physics,
          itemCount: pageCount + 1,
          itemScrollController: controllers.itemScrollController,
          itemPositionsListener: itemPositionsListener,
          scrollOffsetController: controllers.scrollOffsetController,
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

    final notifier = ref.read(
      comicReaderStateProvider(routerPayloadCache).notifier,
    );

    final images = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((p) => p.images),
    );

    // 根据滚动方向预加载不同方向的图片
    if (_visibleFirstIndex > lastIndex) {
      // 向上滚动，预加载上方图片
      preloadImages(firstIndex - 1, firstIndex - maxPreloadCount, images);
    } else {
      // 向下滚动，预加载下方图片
      preloadImages(lastIndex + 1, lastIndex + maxPreloadCount, images);
    }

    _visibleFirstIndex = firstIndex;

    notifier.onPageNoChanged(lastIndex.clamp(0, images.length - 1));
  }
}
