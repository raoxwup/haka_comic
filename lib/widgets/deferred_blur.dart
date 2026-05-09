import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/widgets/with_blur.dart';

/// 按需启用毛玻璃的包装组件。
///
/// - [active] 为 true 时立即启用 [WithBlur]；
/// - [active] 从 true 变为 false 后，等待 [retainDuration]（通常等于外层隐藏
///   动画时长）再真正卸掉 [BackdropFilter]，避免动画中途模糊突然消失；
/// - [active] 为 false 且冷却期已过时，直接返回 [child]，从而短路掉
///   [BackdropFilter] 的全屏背景采样开销。
class DeferredBlur extends StatefulWidget {
  const DeferredBlur({
    super.key,
    required this.active,
    required this.child,
    this.blur = 15.0,
    this.borderRadius = BorderRadius.zero,
    this.retainDuration = const Duration(milliseconds: 250),
  });

  final bool active;
  final Widget child;
  final double blur;
  final BorderRadius borderRadius;
  final Duration retainDuration;

  @override
  State<DeferredBlur> createState() => _DeferredBlurState();
}

class _DeferredBlurState extends State<DeferredBlur> {
  late bool _blurActive = widget.active;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant DeferredBlur oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _timer?.cancel();
      _timer = null;
      if (!_blurActive) {
        setState(() => _blurActive = true);
      }
    } else if (_blurActive) {
      _timer?.cancel();
      _timer = Timer(widget.retainDuration, () {
        if (!mounted) return;
        setState(() => _blurActive = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_blurActive) return widget.child;
    return WithBlur(
      blur: widget.blur,
      borderRadius: widget.borderRadius,
      child: widget.child,
    );
  }
}
