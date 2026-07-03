import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/local_favorites_helper.dart';
import 'package:haka_comic/widgets/toast.dart';

class SortFolders extends StatefulWidget {
  const SortFolders({super.key, required this.folders});

  final List<LocalFolder> folders;

  @override
  State<SortFolders> createState() => _SortFoldersState();
}

class _SortFoldersState extends State<SortFolders> {
  late final _helper = LocalFavoritesHelper();
  late final List<LocalFolder> _folders;

  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _folders = List.of(widget.folders);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_saving) return;
    setState(() {
      final item = _folders.removeAt(oldIndex);
      _folders.insert(newIndex, item);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_dirty) {
      context.pop(false);
      return;
    }

    setState(() => _saving = true);
    try {
      await _helper.updateFolderOrder(_folders.map((e) => e.id).toList());
      if (!mounted) return;
      Toast.show(message: '保存成功');
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      Toast.show(message: '保存失败');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排序'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.pop(false),
        ),
        actions: [
          TextButton(
            onPressed: (_dirty && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _folders.isEmpty
          ? const Center(child: Text('没有可排序的收藏夹'))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _folders.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return ListTile(
                  key: ValueKey(folder.id),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('漫画：${folder.comicCount}'),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
    );
  }
}
