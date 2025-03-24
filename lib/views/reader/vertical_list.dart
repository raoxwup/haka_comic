import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/models.dart';

/// 条漫模式
class VerticalList extends StatefulWidget {
  const VerticalList({super.key, required this.images});

  final List<ChapterImage> images;

  @override
  State<VerticalList> createState() => _VerticalListState();
}

class _VerticalListState extends State<VerticalList> {
  bool _isCtrlPressed = false;

  int _activePointers = 0;
  ScrollPhysics _listPhysics = const AlwaysScrollableScrollPhysics();

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isDesktop) return false;
    final key = event.logicalKey;
    final isControl =
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;

    if (event is KeyDownEvent && isControl) {
      setState(() => _isCtrlPressed = true);
    } else if (event is KeyUpEvent && isControl) {
      setState(() => _isCtrlPressed = false);
    }

    return false;
  }

  @override
  void initState() {
    if (_isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (_isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _updatePointerCount(1),
      onPointerUp: (event) => _updatePointerCount(-1),
      onPointerCancel: (event) => _updatePointerCount(-1),
      child: InteractiveViewer(
        scaleEnabled: _isDesktop ? _isCtrlPressed : true,
        minScale: 1,
        maxScale: 3.5,
        child: ListView.builder(
          physics: _listPhysics,
          itemCount: widget.images.length,
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
            child: CircularProgressIndicator(value: downloadProgress.progress),
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
