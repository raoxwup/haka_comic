import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/shadow_text.dart';

/// 页码
class ReaderPageNoTag extends ConsumerWidget {
  const ReaderPageNoTag({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comicReaderStateProvider(routerPayloadCache));
    final title = state.chapter.title;
    final pageNo = state.correctPageNo;
    final total = state.correctPageCount;

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
