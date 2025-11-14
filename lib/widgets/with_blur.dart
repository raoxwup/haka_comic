import 'dart:ui';
import 'package:flutter/material.dart';

class WithBlur extends StatelessWidget {
  const WithBlur({
    super.key,
    this.blur = 15.0,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final double blur;

  final Widget child;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: borderRadius,
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
