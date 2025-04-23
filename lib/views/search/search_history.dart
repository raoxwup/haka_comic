import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/tag.dart';
import 'package:provider/provider.dart';

class SearchHistory extends StatefulWidget {
  const SearchHistory({super.key});

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
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
                Text('搜索历史', style: context.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    context.read<SearchProvider>().clear();
                  },
                  icon: const Icon(Icons.delete_sweep),
                ),
              ],
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children:
                  history
                      .map(
                        (e) => Tag(
                          tag: e,
                          size: TagSize.medium,
                          color: context.colorScheme.surfaceContainerHighest,
                          onPressed: () {
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
