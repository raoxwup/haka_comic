import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class Item extends StatelessWidget {
  const Item({super.key, required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

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
            color: context.colorScheme.secondaryContainer.withValues(
              alpha: 0.45,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
