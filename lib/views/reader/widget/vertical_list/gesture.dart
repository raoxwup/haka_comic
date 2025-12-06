import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart';

class ScrollPhysicsInherited extends InheritedWidget {
  final ScrollPhysics physics;

  const ScrollPhysicsInherited({
    super.key,
    required this.physics,
    required super.child,
  });

  static ScrollPhysics? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScrollPhysicsInherited>()
        ?.physics;
  }

  @override
  bool updateShouldNotify(ScrollPhysicsInherited oldWidget) {
    return physics != oldWidget.physics;
  }
}

class GestureWrapper extends StatefulWidget {
  const GestureWrapper({
    super.key,
    required this.child,
    this.initialPhysics = const BouncingScrollPhysics(),
    required this.jumpOffset,
    required this.openOrCloseToolbar,
  });

  final Widget child;
  final ScrollPhysics initialPhysics;
  final void Function(double) jumpOffset;
  final VoidCallback openOrCloseToolbar;

  @override
  State<GestureWrapper> createState() => _GestureWrapperState();
}

class _GestureWrapperState extends State<GestureWrapper>
    with SingleTickerProviderStateMixin {
  /// 当前触摸点个数
  int _activePointers = 0;

  /// 滑动控制
  late ScrollPhysics _listPhysics = widget.initialPhysics;

  ///双击缩放相关
  final _transformationController = TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  /// 更新触摸点数量并相应地更新滚动物理效果
  void _updatePointerCount(int delta) {
    final newCount = _activePointers + delta;
    // 确保计数不会为负
    final clampedCount = newCount.clamp(0, double.maxFinite.toInt());

    if (clampedCount == _activePointers) return;

    final newPhysics = clampedCount >= 2
        ? const NeverScrollableScrollPhysics()
        : widget.initialPhysics;

    // 优化：只在物理效果类型变化时才调用setState
    if (newPhysics.runtimeType != _listPhysics.runtimeType) {
      setState(() {
        _activePointers = clampedCount;
        _listPhysics = newPhysics;
      });
    } else {
      // 仅更新内部状态不触发重建
      _activePointers = clampedCount;
    }
  }

  /// 双击放大/恢复
  void _handleDoubleTap() {
    Matrix4 endMatrix;
    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()
        ..translateByVector3(
          Vector3(
            -_doubleTapPosition.dx * 2.0,
            -_doubleTapPosition.dy * 2.0,
            0.0,
          ),
        )
        ..scaleByVector3(Vector3(3.0, 3.0, 1.0));
    }
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController));
    _animationController.forward(from: 0);
  }

  /// 获取双击位置
  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          _transformationController.value = _animation.value;
        });
  }

  @override
  void dispose() {
    _transformationController.dispose();

    _animationController.dispose();

    super.dispose();
  }

  late TapDownDetails _tapDownDetails;

  void _handleTap() {
    final height = context.height;
    final appConf = AppConf();
    double centerFraction = appConf.verticalCenterFraction;
    double topFraction = (1 - centerFraction) / 2;

    final slipFactor = appConf.slipFactor;

    final topHeight = height * topFraction;
    final centerHeight = height * centerFraction;

    final dy = _tapDownDetails.localPosition.dy;
    if (dy < topHeight) {
      widget.jumpOffset(height * slipFactor * -1);
    } else if (dy < (topHeight + centerHeight)) {
      widget.openOrCloseToolbar();
    } else {
      widget.jumpOffset(height * slipFactor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCtrlPressed = context.select<ReaderProvider, bool>(
      (value) => value.isCtrlPressed,
    );
    return ScrollPhysicsInherited(
      physics: _listPhysics,
      child: Listener(
        onPointerDown: (event) => _updatePointerCount(1),
        onPointerUp: (event) => _updatePointerCount(-1),
        onPointerCancel: (event) => _updatePointerCount(-1),
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: (details) => _tapDownDetails = details,
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            scaleEnabled: isDesktop ? isCtrlPressed : true,
            minScale: 1,
            maxScale: 3.5,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
