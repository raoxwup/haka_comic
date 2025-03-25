import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 条漫模式
class VerticalList extends StatefulWidget {
  const VerticalList({
    super.key,
    required this.images,
    required this.onItemVisibleChanged,
  });

  final List<ChapterImage> images;

  final ValueChanged<int> onItemVisibleChanged;

  @override
  State<VerticalList> createState() => _VerticalListState();
}

class _VerticalListState extends State<VerticalList> {
  /// ctrl是否点击
  bool _isCtrlPressed = false;

  /// 当前触摸点
  int _activePointers = 0;

  /// 滑动控制
  ScrollPhysics _listPhysics = const AlwaysScrollableScrollPhysics();

  /// 列表控制
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController itemScrollController = ItemScrollController();

  /// 已加载图片索引
  final Set<int> _loadedImages = {};

  /// 可见的第一项图片索引
  int _visibleFirstIndex = 0;

  bool _handleKeyEvent(KeyEvent event) {
    if (!isDesktop) return false;
    final key = event.logicalKey;
    final isControl =
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;

    if (event is KeyDownEvent && isControl) {
      setState(() {
        _isCtrlPressed = true;
        _listPhysics = const NeverScrollableScrollPhysics();
      });
    } else if (event is KeyUpEvent && isControl) {
      setState(() {
        _isCtrlPressed = false;
        _listPhysics = const AlwaysScrollableScrollPhysics();
      });
    }

    return false;
  }

  @override
  void initState() {
    if (isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    super.initState();
  }

  @override
  void dispose() {
    if (isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }

    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _updatePointerCount(1),
      onPointerUp: (event) => _updatePointerCount(-1),
      onPointerCancel: (event) => _updatePointerCount(-1),
      child: InteractiveViewer(
        scaleEnabled: isDesktop ? _isCtrlPressed : true,
        minScale: 1,
        maxScale: 3.5,
        child: ScrollablePositionedList.builder(
          padding: EdgeInsets.zero,
          physics: _listPhysics,
          itemCount: widget.images.length,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          itemBuilder: (context, index) {
            final item = widget.images[index];
            return VerticalImage(url: item.media.url);
          },
        ),
      ),
    );
  }

  void _updatePointerCount(int delta) {
    final newCount = _activePointers + delta;
    setState(() {
      _activePointers = newCount >= 0 ? newCount : 0;
      // 触摸点 >=2 时禁用滚动 只响应缩放
      _listPhysics =
          _activePointers >= 2
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics();
    });
  }

  void _onItemPositionsChanged() {
    final positions = itemPositionsListener.itemPositions.value;
    final visibleIndices =
        positions
            .where(
              (position) =>
                  position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
            )
            .map((position) => position.index)
            .toList();
    int lastIndex = visibleIndices.last;
    int firstIndex = visibleIndices.first;
    if (_visibleFirstIndex > lastIndex) {
      _preloadImages(firstIndex - 1, firstIndex - 3); // 上翻
    } else {
      _preloadImages(lastIndex + 1, lastIndex + 3); // 下翻
    }

    _visibleFirstIndex = firstIndex;

    widget.onItemVisibleChanged(lastIndex);
  }

  /// 预加载
  void _preloadImages(int startIndex, int endIndex) {
    for (int i = startIndex; i <= endIndex; i++) {
      if (i < 0 || i >= widget.images.length) continue;

      if (_loadedImages.contains(i)) continue;

      final imageUrl = widget.images[i].media.url;
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      precacheImage(imageProvider, context);

      _loadedImages.add(i);
    }
  }
}

class VerticalImage extends StatefulWidget {
  const VerticalImage({super.key, required this.url});

  final String url;

  @override
  State<VerticalImage> createState() => _VerticalImageState();
}

class _VerticalImageState extends State<VerticalImage> {
  UniqueKey key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: BoxFit.fitWidth,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return SizedBox(
          height: size.height * 0.6,
          width: size.width,
          child: Center(
            child: CircularProgressIndicator(
              value: downloadProgress.progress ?? 0,
              strokeWidth: 3,
              constraints: BoxConstraints.tight(const Size(28, 28)),
              backgroundColor: Colors.grey.shade300,
              color: context.colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
        );
      },
      fadeOutDuration: Duration.zero,
      errorWidget:
          (context, url, error) => Center(
            child: IconButton(
              onPressed: () => setState(() => key = UniqueKey()),
              icon: Icon(Icons.refresh),
            ),
          ),
      imageBuilder: (context, imageProvider) {
        return Image(image: imageProvider);
      },
    );
  }
}
