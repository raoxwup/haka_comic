import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/views/settings/block_list_page.dart';
import 'package:provider/provider.dart';

class TagBlock extends StatelessWidget {
  const TagBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final blockedTags = context.select<BlockProvider, List<String>>(
      (p) => p.blockedTags,
    );
    final provider = context.read<BlockProvider>();

    return BlockListPage(
      items: blockedTags,
      addDialogTitle: '添加标签',
      inputHintText: '输入标签（2~20个字符）',
      lengthErrorMessage: '标签长度应为2~20个字符',
      onInsert: provider.insertTag,
      onDelete: provider.deleteTag,
    );
  }
}
