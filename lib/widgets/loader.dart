import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';

class Loader {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show({Widget? message}) {
    if (_isVisible) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _LoaderWidget(message: message);
      },
    );
    _insertOverlay();
  }

  static void hide() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  static void _insertOverlay() {
    if (_overlayEntry == null) return;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay != null && !_isVisible) {
      overlay.insert(_overlayEntry!);
      _isVisible = true;
    }
  }
}

class _LoaderWidget extends StatefulWidget {
  const _LoaderWidget({required this.message});

  final Widget? message;

  @override
  State<_LoaderWidget> createState() => __LoaderWidgetState();
}

class __LoaderWidgetState extends State<_LoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (widget.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: widget.message,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
