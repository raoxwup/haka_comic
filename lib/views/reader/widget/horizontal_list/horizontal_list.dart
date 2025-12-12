import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/comic_list_mixin.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/controller_provider.dart';
import 'package:haka_comic/views/reader/providers/read_mode_provider.dart';
import 'package:haka_comic/views/reader/providers/toolbar_provider.dart';
import 'package:haka_comic/views/reader/state/list_controllers_state.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/views/reader/utils/utils.dart';
import 'package:haka_comic/views/reader/widget/comic_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 条漫模式
class HorizontalList extends ConsumerStatefulWidget {
  const HorizontalList({super.key});

  @override
  ConsumerState<HorizontalList> createState() => _HorizontalListState();
}

class _HorizontalListState extends ConsumerState<HorizontalList>
    with ComicListMixin {
  /// 可见的第一项图片索引 - 用于判断滚动方向
  int _visibleFirstIndex = 0;

  /// 获取当前章节ID
  String get cid => ref.watch(
    comicReaderStateProvider(routerPayloadCache).select((p) => p.id),
  );

  ReadMode get readMode => ref.watch(readModeProvider);

  ListControllersState get controllers => ref.watch(listControllersProvider);
  ListControllersNotifier get controllersNotifier =>
      ref.read(listControllersProvider.notifier);

  ComicReaderStateNotifier get stateNotifier =>
      ref.read(comicReaderStateProvider(routerPayloadCache).notifier);

  void jumpToPage() {
    final initialIndex = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((p) => p.correctPageNo),
    );
    controllers.pageController.jumpToPage(initialIndex);
    _onPageChanged(initialIndex);
  }

  TapDownDetails? _tapDetails;

  void _handleTap() {
    if (_tapDetails == null) return;
    final width = context.width;
    double centerFraction = AppConf().horizontalCenterFraction;
    double leftFraction = (1 - centerFraction) / 2;

    final leftWidth = width * leftFraction;
    final centerWidth = width * centerFraction;

    final dx = _tapDetails!.localPosition.dx;

    final isReverse = readMode.isReverse;

    if (dx < leftWidth) {
      controllersNotifier.pageTurnForHorizontal(isReverse);
    } else if (dx < (leftWidth + centerWidth)) {
      final notifier = ref.read(toolbarProvider.notifier);
      notifier.openOrCloseToolbar();
    } else {
      controllersNotifier.pageTurnForHorizontal(!isReverse);
    }
  }

  bool _lock = false;
  void _handleScroll(PointerScrollEvent event) {
    if (_lock) return;
    _lock = true;

    if (event.scrollDelta.dy > 0) {
      controllersNotifier.pageTurnForHorizontal();
    } else if (event.scrollDelta.dy < 0) {
      controllersNotifier.pageTurnForHorizontal(false);
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      _lock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = ref.watch(
      comicReaderStateProvider(
        routerPayloadCache,
      ).select((p) => p.correctPageCount),
    );

    final images = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((p) => p.images),
    );

    final multiPageImages = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((p) => p.multiImages),
    );

    ref.listen(readModeProvider, (prev, next) {
      if (prev?.isDoublePage != next.isDoublePage) {
        jumpToPage();
      }
    });

    return GestureDetector(
      onTapDown: (details) {
        _tapDetails = details;
      },
      onTap: _handleTap,
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
              pageController: controllers.pageController,
              onPageChanged: _onPageChanged,
              reverse: readMode.isReverse,
              builder: (context, index) {
                if (!readMode.isDoublePage) {
                  final item = images[index];
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

                final items = multiPageImages[index];
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return PhotoViewGalleryPageOptions.customChild(
                  childSize: size * 2,
                  minScale: PhotoViewComputedScale.contained * 1.0,
                  maxScale: PhotoViewComputedScale.covered * 10.0,
                  child: buildPageImages(items, readMode.isReverse),
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
      ),
    );
  }

  Widget buildPageImages(List<ChapterImage> images, bool isReverse) {
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

  void _onPageChanged(int index) {
    final isDoublePage = readMode.isDoublePage;
    var i = isDoublePage ? toCorrectSinglePageNo(index, 2) : index;
    final images = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((p) => p.images),
    );

    if (_visibleFirstIndex > index) {
      final start = i - 1;
      final end = i - maxPreloadCount;
      preloadImages(start, end, images);
    } else {
      int part = i;
      if (isDoublePage) {
        part = part + 1;
      }
      preloadImages(part + 1, part + maxPreloadCount, images);
    }

    _visibleFirstIndex = index;

    stateNotifier.onPageNoChanged(i);
  }
}
