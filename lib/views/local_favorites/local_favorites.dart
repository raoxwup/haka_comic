import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/local_favorites_helper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/local_favorites/folder_comics.dart';
import 'package:haka_comic/views/local_favorites/sort_folders.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class LocalFavorites extends StatefulWidget {
  const LocalFavorites({super.key});

  @override
  State<LocalFavorites> createState() => _LocalFavoritesState();
}

class _LocalFavoritesState extends State<LocalFavorites> with RequestMixin {
  LocalFolder? selectedFolder;
  bool isSearchingComic = false;
  late final _helper = LocalFavoritesHelper();
  late final _getFoldersHandler = _helper.getFoldersWithCount.useRequest(
    onSuccess: (data) {
      Log.i('Get local folders success', data.toString());
    },
    onError: (e) => Log.e('Get local folders error', error: e),
  );

  late final _getFavoritedComicCount = _helper.getFavoritedComicCount
      .useRequest(
        onSuccess: (data) {
          Log.i('Get favorited comic count success', data.toString());
        },
        onError: (e) => Log.e('Get favorited comic count error', error: e),
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
            onChanged: (value) {
              name = value;
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
                context.pop(name);
              },
              child: const Text('新建'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;

    _createFolderHandler.run(name.trim());
  }

  @override
  List<RequestHandler> registerHandler() => [
    _getFoldersHandler,
    _createFolderHandler,
    _deleteFolderHandler,
    _renameFolderHandler,
    _getFavoritedComicCount,
  ];

  Future<void> _sortFolders(List<LocalFolder> folders) async {
    final isSorted = await showDialog<bool>(
      useSafeArea: false,
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Dialog(
              insetPadding: UiMode.m1(context)
                  ? .zero
                  : const .symmetric(horizontal: 40, vertical: 24),
              child: SizedBox(
                width: UiMode.m1(context) ? constraints.maxWidth : 400,
                height: UiMode.m1(context) ? constraints.maxHeight : null,
                child: SortFolders(folders: folders),
              ),
            );
          },
        );
      },
    );

    if (isSorted == true) {
      _getFoldersHandler.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地收藏夹'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      endDrawer: UiMode.m1(context)
          ? Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: _buildFolders(),
            )
          : null,
      body: Row(
        spacing: 5,
        children: [
          if (!UiMode.m1(context))
            Container(
              width: 270,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    width: 2,
                    color: context.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: _buildFolders(),
            ),
          Expanded(child: FolderComics(folder: selectedFolder)),
        ],
      ),
    );
  }

  final entries = <ContextMenuEntry>[
    MenuItem(
      label: Text(
        '重命名',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.edit),
      value: 'rename',
    ),
    MenuItem(
      label: Text(
        '删除',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.delete),
      value: 'delete',
    ),
  ];

  late final menu = ContextMenu(
    entries: entries,
    padding: const EdgeInsets.all(8.0),
  );

  late final _deleteFolderHandler = _helper.deleteFolder.useRequest(
    manual: true,
    onSuccess: (_, id) {
      Log.i('Delete folder success', id.toString());
      if (selectedFolder?.id == id) {
        selectedFolder = null;
      }
      _getFoldersHandler.refresh();
    },
    onError: (e, _) {
      Log.e('Delete folder error', error: e);
      Toast.show(message: '删除失败');
    },
  );

  late final _renameFolderHandler = _helper.renameFolder.useRequest(
    manual: true,
    onSuccess: (_, payload) {
      Log.i('Rename folder success', payload.id.toString());
      _getFoldersHandler.refresh();
    },
    onError: (e, _) {
      Log.e('Rename folder error', error: e);
      Toast.show(message: '重命名失败');
    },
  );

  void _onFolderItemSelected(String value, LocalFolder folder) {
    switch (value) {
      case 'rename':
        _renameFolder(folder);
        break;
      case 'delete':
        _deleteFolder(folder);
        break;
    }
  }

  // 类似于_createFolder，弹窗修改
  Future<void> _renameFolder(LocalFolder folder) async {
    if (_renameFolderHandler.state.loading) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        String name = folder.name;
        final controller = TextEditingController(text: folder.name);
        return AlertDialog(
          title: const Text('重命名收藏夹'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入收藏夹名称'),
            onChanged: (value) => name = value,
            onSubmitted: (value) => context.pop(value),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('取消')),
            TextButton(
              onPressed: () => context.pop(name),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    if (trimmed == folder.name) return;

    final folders = _getFoldersHandler.state.data;
    final conflict =
        folders?.any((e) => e.id != folder.id && e.name.trim() == trimmed) ??
        false;
    if (conflict) {
      Toast.show(message: '「$trimmed」已存在');
      return;
    }

    _renameFolderHandler.run(RenameFolderPayload(id: folder.id, name: trimmed));
  }

  // 需要弹窗确认
  Future<void> _deleteFolder(LocalFolder folder) async {
    if (_deleteFolderHandler.state.loading) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text(
            '确定删除收藏夹「${folder.name}」？\n'
            '删除后收藏夹中的漫画也将被删除。',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    _deleteFolderHandler.run(folder.id);
  }

  Widget _folderTile({
    required Key key,
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: key,
      selected: selected,
      selectedTileColor: context.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      ),
      title: Text(
        title,
        style: context.textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text('$count'),
      leading: Icon(Icons.folder, size: 36, color: context.colorScheme.primary),
      onTap: onTap,
    );
  }

  Widget _folderActions(List<LocalFolder> data) {
    return Padding(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      child: Row(
        spacing: 5,
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onPressed: () => _sortFolders(data),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建收藏夹',
            onPressed: _createFolderHandler.state.loading
                ? null
                : _createFolder,
          ),
        ],
      ),
    );
  }

  Widget _folderList(List<LocalFolder> data) {
    final total = _getFavoritedComicCount.state.data ?? 0;

    return Expanded(
      child: ListView.builder(
        itemCount: data.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _folderTile(
              key: const ValueKey('all'),
              title: '全部',
              count: total,
              selected: selectedFolder == null,
              onTap: () {
                if (selectedFolder == null) return;
                setState(() => selectedFolder = null);
              },
            );
          }

          final folder = data[index - 1];
          return ContextMenuRegion(
            contextMenu: menu,
            onItemSelected: (value) => _onFolderItemSelected(value, folder),
            child: _folderTile(
              key: ValueKey(folder.id),
              title: folder.name,
              count: folder.comicCount,
              selected: selectedFolder?.id == folder.id,
              onTap: () {
                if (selectedFolder?.id == folder.id) return;
                setState(() => selectedFolder = folder);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolders() {
    return SafeArea(
      child: switch (_getFoldersHandler.state) {
        Success(:final data) =>
          data.isEmpty
              ? Column(
                  spacing: 10,
                  mainAxisAlignment: .center,
                  children: [
                    const Text('没有收藏夹，新建一个？'),
                    TextButton(
                      onPressed: _createFolder,
                      child: const Text('新建'),
                    ),
                  ],
                )
              : Column(children: [_folderActions(data), _folderList(data)]),

        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _getFoldersHandler.refresh,
        ),

        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
