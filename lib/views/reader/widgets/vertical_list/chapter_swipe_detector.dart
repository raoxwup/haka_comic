import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/utils/request/request_state.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';

/// 条漫模式下的边缘滑动切章。
/// 左右边缘按下后横向拖动:当前页跟手平移 + 下沉 + z 轴缩放。
/// 松手时距离 ≥ 屏宽 50% 或 fling 够快则提交,否则回弹。
class ChapterSwipeDetector extends StatefulWidget {
  final Widget child;
  const ChapterSwipeDetector({super.key, required this.child});

  @override
  State<ChapterSwipeDetector> createState() => _ChapterSwipeDetectorState();
}

enum _Edge { left, right }

enum _Phase { idle, dragging, bouncing, committing }

class _ChapterSwipeDetectorState extends State<ChapterSwipeDetector>
    with SingleTickerProviderStateMixin {
  int? _pointer;
  _Edge? _edge;
  double _startX = 0;
  double _startY = 0;
  bool _activated = false;
  bool _crossedThreshold = false;

  Offset _lastPos = Offset.zero;
  Duration _lastTs = Duration.zero;
  double _velocity = 0;

  final ValueNotifier<double> _dragDx = ValueNotifier(0.0);
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  late final Listenable _transformListenable;

  late final AnimationController _anim;
  _Phase _phase = _Phase.idle;
  double _animStartDx = 0;
  double _animStartProgress = 0;
  double _commitTargetDx = 0;

  static const double _minDrag = 18.0;
  static const double _edgeWidthRatio = 0.25;
  static const double _fallbackInset = 24.0;
  static const double _thresholdRatio = 0.5;
  static const double _flingVelocityThreshold = 1200.0;
  static const double _sinkMax = 40.0;
  static const double _scaleDelta = 0.08;

  static const Cubic _bounceDxCurve = Cubic(0.175, 0.885, 0.32, 1.08);
  static const Curve _bounceRestCurve = Curves.easeOutCubic;
  static const Curve _commitCurve = Curves.fastEaseInToSlowEaseOut;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: Duration.zero)
      ..addListener(_onAnimTick);
    _transformListenable = Listenable.merge([_dragDx, _progress]);
  }

  @override
  void dispose() {
    _anim.dispose();
    _dragDx.dispose();
    _progress.dispose();
    super.dispose();
  }

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

  double get _screenW => MediaQuery.sizeOf(context).width;

  void _onDown(PointerDownEvent e, _Edge edge) {
    if (_anim.isAnimating) {
      _anim.stop();
      _phase = _Phase.dragging;
      _pointer = e.pointer;
      _edge = edge;
      _startX = e.position.dx - _dragDx.value;
      _startY = e.position.dy;
      _activated = _dragDx.value.abs() > 0;
      _crossedThreshold = _progress.value >= _thresholdRatio;
      _lastPos = e.position;
      _lastTs = e.timeStamp;
      _velocity = 0;
      return;
    }

    if (_pointer != null || _blocked) return;
    final r = context.reader;
    if (edge == _Edge.left && r.isFirstChapter) return;
    if (edge == _Edge.right && r.isLastChapter) return;

    _pointer = e.pointer;
    _edge = edge;
    _startX = e.position.dx;
    _startY = e.position.dy;
    _activated = false;
    _crossedThreshold = false;
    _lastPos = e.position;
    _lastTs = e.timeStamp;
    _velocity = 0;
    _phase = _Phase.dragging;
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final dx = e.position.dx - _startX;
    final dy = e.position.dy - _startY;

    if (!_activated) {
      if (dx.abs() < _minDrag) return;
      if (dx.abs() < dy.abs() * 1.5) {
        _cancel();
        return;
      }
      final dirOk = (_edge == _Edge.left) ? dx > 0 : dx < 0;
      if (!dirOk) {
        _cancel();
        return;
      }
      _activated = true;
    }

    final dt = (e.timeStamp - _lastTs).inMicroseconds / 1e6;
    if (dt > 0) {
      _velocity = (e.position.dx - _lastPos.dx) / dt;
    }
    _lastPos = e.position;
    _lastTs = e.timeStamp;

    _dragDx.value = dx;
    _progress.value = (dx.abs() / _screenW).clamp(0.0, 1.0);

    if (_progress.value >= _thresholdRatio && !_crossedThreshold) {
      HapticFeedback.selectionClick();
      _crossedThreshold = true;
    } else if (_progress.value < _thresholdRatio && _crossedThreshold) {
      _crossedThreshold = false;
    }
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    if (!_activated) {
      _cancel();
      return;
    }

    final distanceOk = _progress.value >= _thresholdRatio;
    final flingOk =
        _velocity.abs() >= _flingVelocityThreshold &&
        ((_edge == _Edge.left && _velocity > 0) ||
            (_edge == _Edge.right && _velocity < 0));

    if (distanceOk || flingOk) {
      _startCommit();
    } else {
      _startBounceBack();
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    if (_activated) {
      _startBounceBack();
    } else {
      _cancel();
    }
  }

  void _startBounceBack() {
    _animStartDx = _dragDx.value;
    _animStartProgress = _progress.value;
    _phase = _Phase.bouncing;
    _anim.duration = const Duration(milliseconds: 320);
    _anim.forward(from: 0.0).whenCompleteOrCancel(() {
      if (!mounted || _phase != _Phase.bouncing) return;
      _dragDx.value = 0;
      _progress.value = 0;
      _resetGestureState();
      _phase = _Phase.idle;
    });
  }

  void _startCommit() {
    _animStartDx = _dragDx.value;
    _commitTargetDx = _dragDx.value > 0 ? _screenW : -_screenW;
    _phase = _Phase.committing;
    _anim.duration = const Duration(milliseconds: 350);
    _anim.forward(from: 0.0).whenCompleteOrCancel(() {
      if (!mounted || _phase != _Phase.committing) return;
      HapticFeedback.mediumImpact();
      if (_edge == _Edge.left) {
        context.reader.goPrevious();
      } else {
        context.reader.goNext();
      }
      _dragDx.value = 0;
      _progress.value = 0;
      _resetGestureState();
      _phase = _Phase.idle;
    });
  }

  void _onAnimTick() {
    final t = _anim.value;
    switch (_phase) {
      case _Phase.bouncing:
        // dx 过冲,progress 无过冲
        _dragDx.value = _animStartDx * (1 - _bounceDxCurve.transform(t));
        _progress.value = _animStartProgress * (1 - _bounceRestCurve.transform(t));
        break;
      case _Phase.committing:
        final cv = _commitCurve.transform(t);
        _dragDx.value = _animStartDx + (_commitTargetDx - _animStartDx) * cv;
        _progress.value = (_dragDx.value.abs() / _screenW).clamp(0.0, 1.0);
        break;
      case _Phase.idle:
      case _Phase.dragging:
        break;
    }
  }

  void _cancel() {
    _resetGestureState();
    if (_dragDx.value != 0) _dragDx.value = 0;
    if (_progress.value != 0) _progress.value = 0;
    _phase = _Phase.idle;
  }

  void _resetGestureState() {
    _pointer = null;
    _edge = null;
    _startX = 0;
    _startY = 0;
    _activated = false;
    _crossedThreshold = false;
    _velocity = 0;
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
        ListenableBuilder(
          listenable: _transformListenable,
          builder: (ctx, child) {
            final p = _progress.value;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // 透视
              ..translate(_dragDx.value, _sinkMax * p, 0.0)
              ..scale(1.0 - _scaleDelta * p);
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: child,
            );
          },
          child: widget.child,
        ),
        if (!isFirst) _zone(_Edge.left, inset, zoneW),
        if (!isLast) _zone(_Edge.right, inset, zoneW),
      ],
    );
  }
}
