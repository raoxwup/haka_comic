import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/reader.dart';
import 'package:haka_comic/views/reader/widget/comic_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 条漫模式
class HorizontalList extends StatefulWidget {
  const HorizontalList({
    super.key,
    required this.onItemVisibleChanged,
    required this.pageController,
    required this.isDoublePage,
    required this.images,
    required this.isReverse,
    required this.openOrCloseToolbar,
    required this.multiPageImages,
  });

  /// 图片可见回调
  final ValueChanged<int> onItemVisibleChanged;

  /// 页码控制器
  final PageController pageController;

  final bool isDoublePage;

  final List<ChapterImage> images;

  final bool isReverse;

  final VoidCallback openOrCloseToolbar;

  final List<List<ChapterImage>> multiPageImages;

  @override
  State<HorizontalList> createState() => _HorizontalListState();
}

class _HorizontalListState extends State<HorizontalList> with ComicListMixin {
  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  /// 获取当前章节ID
  String get cid => context.reader.cid;

  /// 是否需要翻转
  bool get isReverse => widget.isReverse;

  /// 是否双页模式
  bool get isDoublePage => widget.isDoublePage;

  void jumpToPage() {
    final reader = context.reader;
    final initialIndex = isDoublePage
        ? toCorrectMultiPageNo(reader.pageNo, 2)
        : reader.pageNo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.pageController.jumpToPage(initialIndex);
      _onPageChanged(initialIndex);
    });
  }

  @override
  void initState() {
    super.initState();
    jumpToPage();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDoublePage != oldWidget.isDoublePage) {
      jumpToPage();
    }
  }

  TapDownDetails? _tapDetails;

  void previousPage() => widget.pageController.previousPage(
    duration: const Duration(milliseconds: 200),
    curve: Curves.linear,
  );

  void nextPage() => widget.pageController.nextPage(
    duration: const Duration(milliseconds: 200),
    curve: Curves.linear,
  );

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
      isReverse ? nextPage() : previousPage();
    } else if (dx < (leftWidth + centerWidth)) {
      widget.openOrCloseToolbar();
    } else {
      isReverse ? previousPage() : nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _tapDetails = details;
      },
      onTap: _handleTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return PhotoViewGallery.builder(
            backgroundDecoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            itemCount: isDoublePage
                ? widget.multiPageImages.length
                : widget.images.length,
            pageController: widget.pageController,
            onPageChanged: _onPageChanged,
            reverse: isReverse,
            builder: (context, index) {
              if (!isDoublePage) {
                final item = widget.images[index];
                return PhotoViewGalleryPageOptions(
                  minScale: PhotoViewComputedScale.contained * 1.0,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  imageProvider: CachedNetworkImageProvider(item.media.url),
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace, retry) {
                    return Center(
                      child: IconButton(
                        onPressed: () async {
                          final provider = CachedNetworkImageProvider(
                            item.media.url,
                          );
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
                    insertImageSize(imageSize);
                  },
                );
              }

              final items = widget.multiPageImages[index];
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return PhotoViewGalleryPageOptions.customChild(
                childSize: size * 2,
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.covered * 10.0,
                child: buildPageImages(items),
              );
            },
            loadingBuilder: (context, event) {
              return Center(
                child: CircularProgressIndicator(
                  value: event?.expectedTotalBytes == null
                      ? 0
                      : event!.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                  strokeWidth: 3,
                  constraints: BoxConstraints.tight(const Size(28, 28)),
                  backgroundColor: Colors.grey.shade300,
                  color: context.colorScheme.primary,
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildPageImages(List<ChapterImage> images) {
    final correctImages = isReverse ? images.reversed.toList() : images;
    final children = correctImages.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Expanded(
        child: Align(
          alignment: index == 0 ? Alignment.centerRight : Alignment.centerLeft,
          child: ComicImage.noUseCache(
            url: item.media.url,
            onImageSizeChanged: (width, height) {
              final size = ImageSize(
                width: width,
                height: height,
                imageId: item.uid,
                cid: cid,
              );
              insertImageSize(size);
            },
          ),
        ),
      );
    }).toList();
    return Row(children: children);
  }

  void _onPageChanged(index) {
    var i = isDoublePage ? toCorrectSinglePageNo(index, 2) : index;

    if (_visibleFirstIndex > index) {
      final start = i - 1;
      final end = i - maxPreloadCount;
      preloadImages(start, end, widget.images);
    } else {
      int part = i;
      if (isDoublePage) {
        part = part + 1;
      }
      preloadImages(part + 1, part + maxPreloadCount, widget.images);
    }

    _visibleFirstIndex = index;

    widget.onItemVisibleChanged(i);
  }
}
