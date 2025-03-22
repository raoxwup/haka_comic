import 'package:flutter/material.dart';
import 'package:haka_comic/views/mine/comments.dart';
import 'package:haka_comic/views/mine/favorites.dart';
import 'package:haka_comic/views/mine/history.dart';

class Mine extends StatefulWidget {
  const Mine({super.key});

  @override
  State<Mine> createState() => _MineState();
}

class _MineState extends State<Mine> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Column(
        children: [
          TabBar(tabs: [Tab(text: '我的收藏'), Tab(text: '浏览历史'), Tab(text: '评论')]),
          Expanded(
            child: TabBarView(
              children: [const Favorites(), const History(), const Comments()],
            ),
          ),
        ],
      ),
    );
  }
}
