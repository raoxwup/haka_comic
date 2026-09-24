import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/views/settings/block_list_page.dart';
import 'package:provider/provider.dart';

class WordBlock extends StatelessWidget {
  const WordBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final blockedWords = context.select<BlockProvider, List<String>>(
      (p) => p.blockedWords,
    );
    final provider = context.read<BlockProvider>();

    return BlockListPage(
      items: blockedWords,
      addDialogTitle: '添加关键词',
      inputHintText: '输入关键词（2~20个字符）',
      lengthErrorMessage: '关键词长度应为2~20个字符',
      onInsert: provider.insertWord,
      onDelete: provider.deleteWord,
    );
  }
}
