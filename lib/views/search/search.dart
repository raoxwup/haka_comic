import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/views/search/hot_search_words.dart';

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
    return RouteAwarePageWrapper(
      onRouteAnimationCompleted:
          () => setState(() => isRouteAnimationCompleted = true),
      child: Scaffold(
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
                icon: Icon(Icons.close),
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.push('/search_comics?keyword=$value');
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              HotSearchWords(
                isRouteAnimationCompleted: isRouteAnimationCompleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
