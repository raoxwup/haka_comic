import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/toast.dart';

class TagBlock extends StatefulWidget {
  const TagBlock({super.key});

  @override
  State<TagBlock> createState() => _TagBlockState();
}

class _TagBlockState extends State<TagBlock> {
  final helper = TagBlockHelper();
  List<String> blockedTags = [];

  Future<void> getBlockedTags() async {
    final tags = await helper.query();
    setState(() {
      blockedTags = tags;
    });
  }

  @override
  void initState() {
    super.initState();
    getBlockedTags();
    helper.addListener(getBlockedTags);
  }

  @override
  void dispose() {
    helper.removeListener(getBlockedTags);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tag屏蔽')),
      body: blockedTags.isEmpty
          ? const Empty()
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: blockedTags.length,
              itemBuilder: (context, index) {
                final tag = blockedTags[index];
                return ListTile(
                  key: ValueKey(tag),
                  title: Text(
                    tag,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await helper.delete(tag);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final tag = await showDialog<String>(
            context: context,
            builder: (context) {
              String input = '';
              return AlertDialog(
                title: const Text('添加Tag'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '输入Tag（2~20个字符）'),
                  onChanged: (value) {
                    input = value;
                  },
                  onSubmitted: (value) {
                    context.pop(value);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop(input);
                    },
                    child: const Text('添加'),
                  ),
                ],
              );
            },
          );
          if (tag == null) return;
          final t = tag.trim();
          if (t.length >= 2 && t.length <= 20) {
            if (blockedTags.contains(t)) {
              Toast.show(message: '「$t」已存在');
              return;
            }
            await helper.insert(t);
            return;
          }
          Toast.show(message: 'Tag长度应为2~20个字符');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
