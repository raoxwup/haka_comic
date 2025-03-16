import 'package:flutter/material.dart';

enum TagSize { small, medium, large }

class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.tag,
    this.size = TagSize.small,
    this.color,
    this.onPressed,
  });

  final String tag;
  final TagSize size;
  final Color? color;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final textStyle = switch (size) {
      TagSize.small => Theme.of(context).textTheme.bodySmall,
      TagSize.medium => Theme.of(context).textTheme.bodyMedium,
      TagSize.large => Theme.of(context).textTheme.bodyLarge,
    };

    final padding = switch (size) {
      TagSize.small => const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      TagSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      TagSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    };

    return InkWell(
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(99)),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(99)),
          color: color ?? Theme.of(context).colorScheme.inversePrimary,
        ),
        child: Text(tag, style: textStyle),
      ),
    );
  }
}
