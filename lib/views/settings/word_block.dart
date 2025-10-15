import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/word_block_helper.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/toast.dart';

class WordBlock extends StatefulWidget {
  const WordBlock({super.key});

  @override
  State<WordBlock> createState() => _WordBlockState();
}

class _WordBlockState extends State<WordBlock> {
  final helper = WordBlockHelper();
  List<String> blockedWords = [];

  Future<void> getBlockedWords() async {
    final words = await helper.query();
    setState(() {
      blockedWords = words;
    });
  }

  @override
  void initState() {
    super.initState();
    getBlockedWords();
    helper.addListener(getBlockedWords);
  }

  @override
  void dispose() {
    helper.removeListener(getBlockedWords);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('标题关键词屏蔽')),
      body: blockedWords.isEmpty
          ? const Empty()
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: blockedWords.length,
              itemBuilder: (context, index) {
                final word = blockedWords[index];
                return ListTile(
                  key: ValueKey(word),
                  title: Text(
                    word,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await helper.delete(word);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final word = await showDialog<String>(
            context: context,
            builder: (context) {
              String input = '';
              return AlertDialog(
                title: const Text('添加关键词'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '输入关键词（2~20个字符）'),
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
          if (word == null) return;
          final w = word.trim();
          if (w.length >= 2 && w.length <= 20) {
            if (blockedWords.contains(w)) {
              Toast.show(message: '「$w」已存在');
              return;
            }
            await helper.insert(w);
            return;
          }
          Toast.show(message: '关键词长度应为2~20个字符');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
