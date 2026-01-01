import 'package:flutter/material.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/extension.dart';

class ReadStatusBar extends StatelessWidget {
  const ReadStatusBar({
    super.key,
    required this.readRecord,
  });

  final ComicReadRecord? readRecord;

  @override
  Widget build(BuildContext context) {
    if (readRecord == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: context.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark,
            color: context.colorScheme.primary,
            size: 18,
          ),
          Expanded(
            child: Text(
              '上次阅读到${readRecord!.chapterTitle} P${readRecord!.pageNo + 1}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
