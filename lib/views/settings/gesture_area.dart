import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class GestureArea extends StatelessWidget {
  const GestureArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手势区域')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Block(
            children: [
              MenuListTile.withAction(
                title: '条漫模式手势区域',
                onTap: () => context.push('/blacklist'),
              ),
              MenuListTile.withAction(
                title: '显示的分类',
                onTap: () => context.push('/visible_categories'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
