import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:provider/provider.dart';

class ComicTagGroup extends StatelessWidget {
  const ComicTagGroup({
    super.key,
    required this.data,
    required this.type,
  });

  final Comic data;
  final String type; // '分类' or '标签'

  @override
  Widget build(BuildContext context) {
    final List<String> tags =
        type == '标签' ? data.tags : data.categories;
    if (tags.isEmpty) return const SizedBox.shrink();

    final paramKey = type == '标签' ? 't' : 'c';

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: context.colorScheme.errorContainer,
          ),
          child: Text(
            '$type : ',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        ...tags.map(
          (e) => InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push('/comics?$paramKey=$e'),
            onLongPress: type == '标签' ? () => _onTagLongPress(context, e) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.colorScheme.primaryContainer.withValues(
                  alpha: 0.45,
                ),
              ),
              child: Text(
                e,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onTagLongPress(BuildContext context, String tag) async {
    final provider = context.read<BlockProvider>();
    final contains = provider.containsTag(tag);
    
    // We shouldn't check mounted here before showing dialog as it's a direct user interaction
    // But we need to handle the result
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(contains ? '取消屏蔽' : '屏蔽'),
          content: Text(contains ? '确定要取消对「$tag」的屏蔽吗？' : '确定要屏蔽「$tag」吗？'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                contains ? provider.deleteTag(tag) : provider.insertTag(tag);
                Toast.show(message: contains ? '已取消屏蔽「$tag」' : '已屏蔽「$tag」');
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
