import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/utils/request/request_state.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';

/// Detects horizontal edge swipes to jump chapters.
/// Left edge swipe → previous chapter, right edge swipe → next chapter.
class ChapterSwipeDetector extends StatefulWidget {
  final Widget child;
  const ChapterSwipeDetector({super.key, required this.child});

  @override
  State<ChapterSwipeDetector> createState() => _ChapterSwipeDetectorState();
}

enum _Edge { left, right }

class _ChapterSwipeDetectorState extends State<ChapterSwipeDetector> {
  int? _pointer;
  _Edge? _edge;
  double? _startX;
  bool _activated = false;

  static const _minDrag = 4.0;
  static const _edgeWidthRatio = 0.25;
  static const _fallbackInset = 24.0;

  bool get _blocked {
    final r = context.reader;
    return r.showToolbar ||
        context.stateReader.lockMenu ||
        r.handler.state is Loading;
  }

  double _edgeInset(BuildContext ctx) {
    final insets = MediaQuery.systemGestureInsetsOf(ctx);
    final max = insets.left > insets.right ? insets.left : insets.right;
    return max > 0 ? max : _fallbackInset;
  }

  void _onDown(PointerDownEvent e, _Edge edge) {
    if (_pointer != null || _blocked) return;
    final r = context.reader;
    if (edge == _Edge.left && r.isFirstChapter) return;
    if (edge == _Edge.right && r.isLastChapter) return;
    _pointer = e.pointer;
    _edge = edge;
    _startX = e.position.dx;
    _activated = false;
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer || _activated) return;
    final dx = e.position.dx - _startX!;
    if (dx.abs() < _minDrag) return;
    // left edge requires rightward drag (dx>0), right edge requires leftward (dx<0)
    _activated = (_edge == _Edge.left) ? dx > 0 : dx < 0;
    if (!_activated) _cancel();
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    if (_activated) {
      HapticFeedback.mediumImpact();
      if (_edge == _Edge.left) {
        context.reader.goPrevious();
      } else {
        context.reader.goNext();
      }
    }
    _cancel();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _cancel();
  }

  void _cancel() {
    _pointer = null;
    _edge = null;
    _startX = null;
    _activated = false;
  }

  Widget _zone(_Edge edge, double inset, double width) {
    return Positioned(
      left: edge == _Edge.left ? inset : null,
      right: edge == _Edge.right ? inset : null,
      top: 0,
      bottom: 0,
      width: width,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _onDown(e, edge),
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onPointerCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.stateSelector((p) => p.enableChapterSwipe);
    if (!enabled) return widget.child;

    final isFirst = context.selector<bool>((p) => p.isFirstChapter);
    final isLast = context.selector<bool>((p) => p.isLastChapter);
    final screenW = MediaQuery.sizeOf(context).width;
    final inset = _edgeInset(context);
    final zoneW = screenW * _edgeWidthRatio;

    return Stack(
      children: [
        widget.child,
        if (!isFirst) _zone(_Edge.left, inset, zoneW),
        if (!isLast) _zone(_Edge.right, inset, zoneW),
      ],
    );
  }
}
