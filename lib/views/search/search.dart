import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/search_provider.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/views/search/filter_panel.dart';
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
  ComicSortType _sortType = ComicSortType.dd;
  Set<String> _categories = {};
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
                  _openSearchComics(value);
                }
              },
            ),
            actions: [
              IconButton(
                tooltip: '筛选',
                icon: const Icon(Icons.filter_list),
                onPressed: _buildFilterPanel,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: history.isEmpty ? 0 : 20,
              children: [
                SearchHistory(onSearch: _openSearchComics),
                HotSearchWords(
                  isRouteAnimationCompleted: completed,
                  onSearch: _openSearchComics,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _buildFilterPanel() {
    showDialog(
      context: context,
      builder: (context) {
        return FilterPanel(
          sortType: _sortType,
          categories: _categories,
          onFilter: _onFilter,
        );
      },
    );
  }

  void _onFilter({
    required Set<String> categories,
    required ComicSortType type,
  }) {
    setState(() {
      _sortType = type;
      _categories = Set.of(categories);
    });
  }

  void _openSearchComics(String keyword) {
    context.push(_buildSearchComicsLocation(keyword));
  }

  String _buildSearchComicsLocation(String keyword) {
    return Uri(
      path: '/search_comics',
      queryParameters: {
        'keyword': keyword,
        'sort': _sortType.name,
        if (_categories.isNotEmpty) 'categories': _categories.toList(),
      },
    ).toString();
  }
}
