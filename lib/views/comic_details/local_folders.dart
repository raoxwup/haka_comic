import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/local_favorites_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class LocalFolders extends StatefulWidget {
  const LocalFolders({super.key, required this.comic});

  final Comic comic;

  @override
  State<LocalFolders> createState() => _LocalFoldersState();
}

class _LocalFoldersState extends State<LocalFolders> with RequestMixin {
  final _helper = LocalFavoritesHelper();

  late final _getFoldersHandler = _helper.getFoldersByComic.useRequest(
    defaultParams: widget.comic.id,
    onSuccess: (data, _) {
      Log.i('Get local folders success', data.toString());
    },
    onError: (e, _) => Log.e('Get local folders error', error: e),
  );

  late final _createFolderHandler = _helper.createFolder.useRequest(
    manual: true,
    onSuccess: (data, name) {
      if (data) {
        Log.i('Create folder success', name);
        _getFoldersHandler.refresh();
      } else {
        Toast.show(message: '「$name」已存在');
        Log.i('Create folder failed. $name already exists', name);
      }
    },
    onError: (e, name) {
      Toast.show(message: '创建失败');
      Log.e('Create folder $name error', error: e);
    },
  );

  List<LocalFolderWithFavorited> cacheFolders = [];
  late final _toggleFolderHandler = _helper.toggleComicInFolder.useRequest(
    manual: true,
    onBefore: (payload) {
      final folders = _getFoldersHandler.state.data ?? [];
      cacheFolders = folders;
      _getFoldersHandler.mutate(
        folders.map((f) {
          if (f.id != payload.folderId) return f;
          final delta = f.favorited ? -1 : 1;
          final nextCount = f.comicCount + delta;
          return LocalFolderWithFavorited(
            id: f.id,
            name: f.name,
            sortOrder: f.sortOrder,
            createdAt: f.createdAt,
            updatedAt: f.updatedAt,
            comicCount: nextCount < 0 ? 0 : nextCount,
            favorited: !f.favorited,
          );
        }).toList(),
      );
    },
    onSuccess: (_, payload) {
      Log.i(
        'Toggle comic in folder success',
        '${payload.comic.id} in ${payload.folderId}',
      );
    },
    onError: (e, _) {
      Log.e('Toggle comic in folder error', error: e);
      Toast.show(message: '操作失败');
      _getFoldersHandler.mutate(cacheFolders);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [
    _getFoldersHandler,
    _createFolderHandler,
    _toggleFolderHandler,
  ];

  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        String name = '';
        return AlertDialog(
          title: const Text('新建收藏夹'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入收藏夹名称'),
            onChanged: (value) => name = value,
            onSubmitted: (value) => context.pop(value),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('取消')),
            TextButton(
              onPressed: () => context.pop(name),
              child: const Text('新建'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;

    _createFolderHandler.run(name.trim());
  }

  void _retry() {
    _getFoldersHandler.refresh();
  }

  Widget _header() {
    final busy = _createFolderHandler.state.loading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Text('收藏夹', style: context.textTheme.titleMedium),
          const Spacer(),
          IconButton(
            tooltip: '刷新',
            onPressed: busy ? null : _retry,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '新建收藏夹',
            onPressed: busy ? null : _createFolder,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _folderTile({
    required LocalFolderWithFavorited folder,
    required VoidCallback onTap,
  }) {
    final enabled = !_toggleFolderHandler.state.loading;
    return Tooltip(
      message: folder.name,
      child: ListTile(
        enabled: enabled,
        title: Text(
          folder.name,
          style: context.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('漫画：${folder.comicCount}'),
        leading: Icon(
          Icons.folder,
          size: 36,
          color: context.colorScheme.primary,
        ),
        trailing: Checkbox(value: folder.favorited, onChanged: (_) => onTap()),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFolders(List<LocalFolderWithFavorited> folders) {
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            const Text('没有收藏夹，新建一个？'),
            TextButton(
              onPressed: _createFolderHandler.state.loading
                  ? null
                  : _createFolder,
              child: const Text('新建'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _folderTile(
          folder: folder,
          onTap: () {
            _toggleFolderHandler.run(
              ToggleComicInFolderPayload(
                comic: widget.comic,
                folderId: folder.id,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: switch (_getFoldersHandler.state) {
        Success(:final data) => Column(
          children: [
            _header(),
            const Divider(height: 1),
            Expanded(child: _buildFolders(data)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Text(
                '勾选可将《${widget.comic.title}》加入/移除对应收藏夹',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _retry,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
