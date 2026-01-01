import 'package:flutter/material.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/views/comic_details/types.dart';

class ComicReadButtons extends StatelessWidget {
  const ComicReadButtons({
    super.key,
    required this.readRecord,
    required this.onStartRead,
  });

  final ComicReadRecord? readRecord;
  final ReadCallback onStartRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 40,
            ),
            child: readRecord != null
                ? FilledButton.tonalIcon(
                    onPressed: () => onStartRead(),
                    label: const Text('从头开始'),
                  )
                : FilledButton(
                    onPressed: () => onStartRead(),
                    child: const Text('开始阅读'),
                  ),
          ),
        ),
        if (readRecord != null)
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 40,
              ),
              child: FilledButton(
                onPressed: () => onStartRead(
                  chapterId: readRecord!.chapterId,
                  pageNo: readRecord!.pageNo,
                ),
                child: const Text('继续阅读'),
              ),
            ),
          ),
      ],
    );
  }
}
