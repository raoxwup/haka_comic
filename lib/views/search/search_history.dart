import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/search/item.dart';
import 'package:provider/provider.dart';

class SearchHistory extends StatefulWidget {
  const SearchHistory({super.key});

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  void clear() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清除'),
          content: const Text('确定要清除所有搜索历史吗？'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      if (mounted) {
        context.read<SearchProvider>().clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> history = context.watch<SearchProvider>().history;
    return history.isEmpty
        ? const SizedBox.shrink()
        : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Row(
              spacing: 5,
              children: [
                Text(
                  '搜索历史',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(onPressed: clear, icon: const Icon(Icons.clear_all)),
              ],
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children:
                  history
                      .map(
                        (e) => Item(
                          title: e,
                          onTap: () {
                            context.read<SearchProvider>().add(e);
                            context.push('/search_comics?keyword=$e');
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        );
  }
}
