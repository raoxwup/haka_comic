import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:vector_math/vector_math_64.dart';

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
  final Set<int> _activePointerIds = {};

  bool _isScrollable = true;

  void _handlePointerChange(PointerEvent event, bool isAdding) {
    if (isAdding) {
      _activePointerIds.add(event.pointer);
    } else {
      _activePointerIds.remove(event.pointer);
    }

    final bool shouldBeScrollable = _activePointerIds.length < 2;

    if (_isScrollable != shouldBeScrollable) {
      _isScrollable = shouldBeScrollable;
      context.stateReader.physics = _isScrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics();
    }
  }

  ///双击缩放相关
  final _transformationController = TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  /// 双击放大/恢复
  void _handleDoubleTap() {
    Matrix4 endMatrix;

    double currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.05) {
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
    final isCtrlPressed = context.stateSelector((p) => p.isCtrlPressed);
    return Listener(
      onPointerDown: (event) => _handlePointerChange(event, true),
      onPointerUp: (event) => _handlePointerChange(event, false),
      onPointerCancel: (event) => _handlePointerChange(event, false),
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (details) => _tapDownDetails = details,
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          scaleEnabled: isDesktop ? isCtrlPressed : true,
          minScale: 1.0,
          maxScale: 3.5,
          child: widget.child,
        ),
      ),
    );
  }
}
