import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/utils/extension.dart';

enum ToastPosition { top, center, bottom }

class Toast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static bool _isVisible = false;

  static void show({
    required String message,
    Duration duration = const Duration(seconds: 2),
    ToastPosition position = ToastPosition.bottom,
    Color? backgroundColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(8),
    ),
    bool dismissOther = true,
  }) {
    if (dismissOther) {
      _dismiss();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        var brightness = Theme.of(context).brightness;
        return _ToastWidget(
          message: message,
          position: position,
          backgroundColor:
              backgroundColor ??
              (brightness == Brightness.light ? Colors.black87 : Colors.white),
          textStyle:
              textStyle ??
              (brightness == Brightness.light
                  ? const TextStyle(color: Colors.white, fontSize: 14)
                  : const TextStyle(color: Colors.black87, fontSize: 14)),
          padding: padding,
          borderRadius: borderRadius,
        );
      },
    );

    _insertOverlay();
    _startTimer(duration);
  }

  static void _insertOverlay() {
    if (_overlayEntry == null) return;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay != null && !_isVisible) {
      overlay.insert(_overlayEntry!);
      _isVisible = true;
    }
  }

  static void _startTimer(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    if (!_isVisible) return;

    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastPosition position;
  final Color backgroundColor;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const _ToastWidget({
    required this.message,
    required this.position,
    required this.backgroundColor,
    required this.textStyle,
    required this.padding,
    required this.borderRadius,
  });

  @override
  __ToastWidgetState createState() => __ToastWidgetState();
}

class __ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getPosition() {
    return switch (widget.position) {
      ToastPosition.top => context.viewInsets.top + 50,
      ToastPosition.center => context.height / 2,
      ToastPosition.bottom => context.height - context.viewInsets.bottom - 100,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _getPosition(),
      width: context.width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: widget.borderRadius,
                  ),
                  padding: widget.padding,
                  child: Text(
                    widget.message,
                    style: widget.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
