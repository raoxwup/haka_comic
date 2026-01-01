import 'dart:io';

import 'package:extended_image/extended_image.dart';
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
  /// 获取当前章节ID
  String get cid => context.reader.id;

  void jumpToPage() {
    final initialIndex = context.reader.pageNo;
    context.reader.pageController.jumpToPage(initialIndex);
    _onPageChanged(initialIndex);
  }

  late TapDownDetails _tapDetails;

  void _handleTap() {
    final width = context.width;
    double centerFraction = AppConf().horizontalCenterFraction;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastIsDoublePage != readMode.isDoublePage) {
        jumpToPage();
      }
    });

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
                    return PhotoViewGalleryPageOptions(
                      minScale: PhotoViewComputedScale.contained * 1.0,
                      maxScale: PhotoViewComputedScale.covered * 4.0,
                      imageProvider: context.reader.type == ReaderType.network
                          ? ExtendedNetworkImageProvider(
                              item.url,
                              timeRetry: const Duration(milliseconds: 300),
                              cache: true,
                            )
                          : ExtendedFileImageProvider(File(item.url)),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace, retry) {
                        return Center(
                          child: IconButton(
                            onPressed: () {
                              clearMemoryImageCache(item.url);
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

                  final items = multiPageImages[index];
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return PhotoViewGalleryPageOptions.customChild(
                    childSize: size * 2,
                    minScale: PhotoViewComputedScale.contained * 1.0,
                    maxScale: PhotoViewComputedScale.covered * 10.0,
                    child: buildPageImages(items, readMode.isReverse),
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

  Widget buildPageImages(List<ImageBase> images, bool isReverse) {
    final correctImages = isReverse ? images.reversed.toList() : images;
    final children = correctImages.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final size = correctImages.length;
      return Expanded(
        child: Align(
          alignment: size == 1
              ? Alignment.center
              : (index == 0 ? Alignment.centerRight : Alignment.centerLeft),
          child: ReaderImage(
            url: item.url,
            enableCache: false,
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

  void _onPageChanged(int index) {
    final isDoublePage = context.reader.readMode.isDoublePage;
    var i = isDoublePage ? toCorrectSinglePageNo(index, 2) : index;

    context.reader.preloadController.onAnchorChanged([i]);

    context.reader.onPageNoChanged(i);
  }
}
