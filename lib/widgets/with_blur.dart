import 'dart:ui';
import 'package:flutter/material.dart';

class WithBlur extends StatelessWidget {
  const WithBlur({super.key, this.blur = 15.0, required this.child});

  final double blur;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.mirror,
        ),
        child: child,
      ),
    );
  }
}
