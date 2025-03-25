import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class IconText extends StatelessWidget {
  const IconText({
    super.key,
    required this.icon,
    required this.text,
    this.spacing = 4,
  });

  final Icon icon;
  final String text;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: spacing,
      children: [icon, Text(text, style: context.textTheme.bodySmall)],
    );
  }
}
