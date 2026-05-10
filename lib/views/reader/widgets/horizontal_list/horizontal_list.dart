import 'dart:io';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/views/reader/widgets/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';
import 'package:haka_comic/views/reader/widgets/reader_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 条漫模式
class HorizontalList extends StatefulWidget {
  const HorizontalList({super.key});

  @override
  State<HorizontalList> createState() => _HorizontalListState();
}

class _HorizontalListState extends State<HorizontalList> with ComicListMixin {
  final Set<String> _reportedImageSizeIds = {};

  /// 获取当前章节ID
  String get cid => context.reader.id;

  void jumpToPage() {
    final initialIndex = context.reader.pageNo;
    context.reader.pageController.jumpToPage(initialIndex);
    _onPageChanged(initialIndex);
  }

  late TapDownDetails _tapDetails;

  void _handleTap() {
    final appConf = AppConf();

    if (!appConf.enableGesture) {
      context.reader.openOrCloseToolbar();
      return;
    }

    final width = context.width;
    double centerFraction = appConf.horizontalCenterFraction;
    double leftFraction = (1 - centerFraction) / 2;

    final leftWidth = width * leftFraction;
    final centerWidth = width * centerFraction;

    final dx = _tapDetails.localPosition.dx;

    final isReverse = context.reader.readMode.isReverse;

    if (dx < leftWidth) {
      context.reader.pageTurnForHorizontal(isReverse);
    } else if (dx < (leftWidth + centerWidth)) {
      context.reader.openOrCloseToolbar();
    } else {
      context.reader.pageTurnForHorizontal(!isReverse);
    }
  }

  void _handleLockTap() {
    final appConf = AppConf();

    if (!appConf.enableGesture) {
      return;
    }

    final width = context.width;
    final halfWidth = width / 2;
    final dx = _tapDetails.localPosition.dx;
    final isReverse = context.reader.readMode.isReverse;
    if (dx < halfWidth) {
      context.reader.pageTurnForHorizontal(isReverse);
    } else {
      context.reader.pageTurnForHorizontal(!isReverse);
    }
  }

  bool _lock = false;
  void _handleScroll(PointerScrollEvent event) {
    if (_lock) return;
    _lock = true;

    if (event.scrollDelta.dy > 0) {
      context.reader.pageTurnForHorizontal();
    } else if (event.scrollDelta.dy < 0) {
      context.reader.pageTurnForHorizontal(false);
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      _lock = false;
    });
  }

  bool? _lastIsDoublePage;

  @override
  Widget build(BuildContext context) {
    final pageCount = context.selector((p) => p.pageCount);

    final images = context.selector((p) => p.images);

    final multiPageImages = context.selector((p) => p.multiPageImages);

    final readMode = context.selector((p) => p.readMode);

    // 仅在单页 / 双页模式切换时做一次页码跳转
    if (_lastIsDoublePage != readMode.isDoublePage) {
      _lastIsDoublePage = readMode.isDoublePage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        jumpToPage();
      });
    }

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(seconds: 2),
                debugOwner: this,
              ),
              (instance) {
                instance.onLongPress = context.stateReader.toggleLockMenu;
              },
            ),
      },
      child: GestureDetector(
        onTapDown: (details) {
          _tapDetails = details;
        },
        onTap: () {
          context.stateReader.lockMenu ? _handleLockTap() : _handleTap();
        },
        child: Listener(
          onPointerSignal: (event) {
            if (HardwareKeyboard.instance.isControlPressed) return;
            if (event is PointerScrollEvent) {
              _handleScroll(event);
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dpr = MediaQuery.devicePixelRatioOf(context);
              // 单页模式按整个可视区域宽度计算，双页模式按半屏宽度计算
              final singlePageLayoutWidth = constraints.maxWidth;
              final doublePageLayoutWidth = constraints.maxWidth / 2;
              final singleCacheWidth = computeImageCacheWidth(
                layoutWidth: singlePageLayoutWidth,
                devicePixelRatio: dpr,
              );
              final doubleCacheWidth = computeImageCacheWidth(
                layoutWidth: doublePageLayoutWidth,
                devicePixelRatio: dpr,
              );
              // 预加载解码宽度与当前显示模式一致
              context.reader.updatePreloadCacheWidth(
                readMode.isDoublePage ? doubleCacheWidth : singleCacheWidth,
              );

              return PhotoViewGallery.builder(
                backgroundDecoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLowest,
                ),
                scrollPhysics: const BouncingScrollPhysics(),
                itemCount: pageCount,
                pageController: context.reader.pageController,
                onPageChanged: _onPageChanged,
                reverse: readMode.isReverse,
                builder: (context, index) {
                  if (!readMode.isDoublePage) {
                    final item = images[index];
                    final ImageProvider base =
                        context.reader.type == ReaderType.network
                        ? CachedNetworkImageProvider(item.url)
                        : FileImage(File(item.url));
                    // 与 ReaderImage / 预加载统一用 ResizeImage 做解码限制，
                    // 保证共享同一个 ImageCache 条目
                    final imageProvider = ResizeImage.resizeIfNeeded(
                      singleCacheWidth,
                      null,
                      base,
                    );
                    return PhotoViewGalleryPageOptions(
                      minScale: PhotoViewComputedScale.contained * 1.0,
                      maxScale: PhotoViewComputedScale.covered * 4.0,
                      imageProvider: imageProvider,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace, retry) {
                        return Center(
                          child: IconButton(
                            onPressed: () async {
                              await _evictImage(item);
                              if (!mounted) return;
                              retry();
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                        );
                      },
                      onImageFrame: (info, synchronousCall) {
                        _reportImageSizeOnce(
                          item,
                          info.image.width,
                          info.image.height,
                        );
                      },
                    );
                  }

                  final items = multiPageImages[index];
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return PhotoViewGalleryPageOptions.customChild(
                    childSize: size * 2,
                    minScale: PhotoViewComputedScale.contained * 1.0,
                    maxScale: PhotoViewComputedScale.covered * 10.0,
                    child: buildPageImages(
                      items,
                      readMode.isReverse,
                      doubleCacheWidth,
                    ),
                  );
                },
                loadingBuilder: (context, event) {
                  final bytes = event?.cumulativeBytesLoaded ?? 0;
                  final value = computeProgress(bytes);
                  return Center(
                    child: CircularProgressIndicator(
                      value: value,
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
        ),
      ),
    );
  }

  Future<void> _evictImage(ImageBase item) async {
    final isNetwork = context.reader.type == ReaderType.network;
    if (isNetwork) {
      await CachedNetworkImage.evictFromCache(item.url);
      return;
    }
    await FileImage(File(item.url)).evict();
  }

  bool _reportImageSizeOnce(ImageBase item, int width, int height) {
    if (!_reportedImageSizeIds.add(item.uid)) return false;
    final imageSize = ImageSize(
      imageId: item.uid,
      width: width,
      height: height,
      cid: cid,
    );
    insertImageSize(imageSize);
    return true;
  }

  Widget buildPageImages(
    List<ImageBase> images,
    bool isReverse,
    int cacheWidth,
  ) {
    final correctImages = isReverse ? images.reversed.toList() : images;
    final children = correctImages.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final size = correctImages.length;
      // 关键点：不要再用 Align 给 ReaderImage 提供 loose 约束。
      // RetryForImage 内部 AnimatedSwitcher 的 Stack 在过渡时尺寸会随
      // 占满整格的占位图和 intrinsic 尺寸的 Image 之间变化，
      // 这会让 Align 的对齐在过渡前后各表现一次，
      // 视觉上就出现“先留缝、加载完成后贴到一起”的跳动。
      // 改成让 Expanded 直接给 ReaderImage tight 约束，
      // 对齐交由 Image 自身的 alignment（配合 BoxFit.contain）来处理。
      return Expanded(
        child: ReaderImage(
          url: item.url,
          enableCache: false,
          cacheWidth: cacheWidth,
          alignment: size == 1
              ? Alignment.center
              : (index == 0 ? Alignment.centerRight : Alignment.centerLeft),
          onImageSizeChanged: (width, height) {
            _reportImageSizeOnce(item, width, height);
          },
        ),
      );
    }).toList();
    return Row(children: children);
  }

  void _onPageChanged(int index) {
    final isDoublePage = context.reader.readMode.isDoublePage;
    var i = isDoublePage ? toCorrectSinglePageNo(index, 2) : index;

    context.reader.preloadController.onAnchorChanged([i]);

    context.reader.onPageNoChanged(i);
  }
}
