import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
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
      body: Center(child: const Text('Search')),
    );
  }
}
