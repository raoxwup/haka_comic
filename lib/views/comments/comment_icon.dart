import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class CommentIcon extends StatelessWidget {
  const CommentIcon({
    super.key,
    this.onTap,
    this.loading = false,
    required this.icon,
    required this.count,
  });

  final VoidCallback? onTap;

  final bool loading;

  final Icon icon;

  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(99),
      child: Padding(
        padding: const .symmetric(horizontal: 6, vertical: 3),
        child: Row(
          spacing: 5,
          mainAxisSize: .min,
          children: [
            loading
                ? CircularProgressIndicator(
                    constraints: .tight(const Size(12, 12)),
                    strokeWidth: 1,
                    color: context.textTheme.bodySmall?.color,
                  )
                : icon,
            Text('$count', style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
