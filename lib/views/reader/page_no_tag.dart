import 'package:flutter/material.dart';
import 'package:haka_comic/views/reader/reader_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/shadow_text.dart';

/// 页码
class ReaderPageNoTag extends StatelessWidget {
  const ReaderPageNoTag({super.key});

  @override
  Widget build(BuildContext context) {
    final (pageNo, title, total) = context.selector(
      (value) =>
          (value.correctPageNo, value.currentChapter.title, value.pageCount),
    );

    return Positioned(
      left: context.left + 12,
      bottom: context.bottom + 12,
      width: context.width / 2,
      child: Row(
        spacing: 5,
        children: [
          Flexible(child: ShadowText(text: title)),
          ShadowText(text: '${pageNo + 1} / $total'),
        ],
      ),
    );
  }
}
