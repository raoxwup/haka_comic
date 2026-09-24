import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/views/settings/blacklist.dart';
import 'package:haka_comic/views/settings/tag_block.dart';
import 'package:haka_comic/views/settings/word_block.dart';

class BlockSettings extends StatelessWidget {
  const BlockSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('屏蔽'),
          bottom: const TabBar(
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: [
              Tab(text: '分类'),
              Tab(text: '标签'),
              Tab(text: '标题关键词'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [Blacklist(), TagBlock(), WordBlock()],
        ),
      ),
    );
  }
}
