import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/views/search/hot_search_words.dart';
import 'package:haka_comic/views/search/search_history.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  bool isRouteAnimationCompleted = false;

  @override
  Widget build(BuildContext context) {
    final List<String> history = context.watch<SearchProvider>().history;
    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: '搜索',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  onPressed: () {
                    if (_searchController.text.isEmpty) {
                      context.pop();
                    } else {
                      _searchController.clear();
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<SearchProvider>().add(value);
                  context.push('/search_comics?keyword=$value');
                }
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: history.isEmpty ? 0 : 20,
              children: [
                const SearchHistory(),
                HotSearchWords(isRouteAnimationCompleted: completed),
              ],
            ),
          ),
        );
      },
    );
  }
}
