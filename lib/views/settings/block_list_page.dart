import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/toast.dart';

typedef BlockItemAction = FutureOr<void> Function(String value);

class BlockListPage extends StatelessWidget {
  const BlockListPage({
    super.key,
    required this.items,
    required this.addDialogTitle,
    required this.inputHintText,
    required this.lengthErrorMessage,
    required this.onInsert,
    required this.onDelete,
    this.minLength = 2,
    this.maxLength = 20,
    this.duplicateMessageBuilder,
  });

  final List<String> items;
  final String addDialogTitle;
  final String inputHintText;
  final String lengthErrorMessage;
  final BlockItemAction onInsert;
  final BlockItemAction onDelete;
  final int minLength;
  final int maxLength;
  final String Function(String value)? duplicateMessageBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: items.isEmpty
          ? const Empty()
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = (constraints.maxWidth / 220)
                    .floor()
                    .clamp(1, 6)
                    .toInt();

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _BlockItemCard(
                      key: ValueKey(item),
                      title: item,
                      onDelete: () async {
                        await onDelete(item);
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _promptAndInsert(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _promptAndInsert(BuildContext context) async {
    final input = await _showInputDialog(context);
    if (input == null) return;

    final value = input.trim();
    if (value.length < minLength || value.length > maxLength) {
      Toast.show(message: lengthErrorMessage);
      return;
    }

    if (items.contains(value)) {
      Toast.show(
        message: duplicateMessageBuilder?.call(value) ?? '「$value」已存在',
      );
      return;
    }

    await onInsert(value);
  }

  Future<String?> _showInputDialog(BuildContext context) async {
    String input = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(addDialogTitle),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: inputHintText),
            onChanged: (value) {
              input = value;
            },
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(input);
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}

class _BlockItemCard extends StatelessWidget {
  const _BlockItemCard({
    super.key,
    required this.title,
    required this.onDelete,
  });

  final String title;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
