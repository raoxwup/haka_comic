import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/widgets/shadow_text.dart';

/// 页码
class ReaderPageNoTag extends StatelessWidget {
  const ReaderPageNoTag({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.selector((p) => p.chapter.title);
    final pageNo = context.selector((p) => p.pageNo);
    final total = context.selector((p) => p.pageCount);

    return Positioned(
      left: context.left + 12,
      bottom: context.bottom + 12,
      width: context.width / 2,
      child: RepaintBoundary(
        child: Row(
          spacing: 5,
          children: [
            Flexible(child: ShadowText(text: title)),
            ShadowText(text: '${pageNo + 1} / $total'),
          ],
        ),
      ),
    );
  }
}
