import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/shadow_text.dart';

/// 页码
class ReaderPageNoTag extends StatelessWidget {
  const ReaderPageNoTag({
    super.key,
    required this.pageNo,
    required this.total,
    required this.title,
  });

  /// 当前阅读的页码
  final int pageNo;

  /// 总页数
  final int total;

  /// 章节标题
  final String title;

  @override
  Widget build(BuildContext context) {
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
