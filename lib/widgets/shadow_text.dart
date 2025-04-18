import 'package:flutter/material.dart';

class ShadowText extends StatelessWidget {
  const ShadowText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        shadows: [
          // 添加8个方向的阴影（偏移1像素）
          Shadow(offset: Offset(-1, -1), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(1, -1), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(-1, 1), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(1, 1), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(-1, 0), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(1, 0), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(0, -1), color: Colors.white, blurRadius: 0),
          Shadow(offset: Offset(0, 1), color: Colors.white, blurRadius: 0),
        ],
      ),
    );
  }
}
