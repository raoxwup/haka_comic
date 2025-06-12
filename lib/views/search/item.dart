import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class Item extends StatelessWidget {
  const Item({super.key, required this.title, this.onTap, this.color});

  final String title;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color:
                color ?? context.colorScheme.surfaceDim.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(title, style: context.textTheme.bodyMedium),
        ),
      ),
    );
  }
}
