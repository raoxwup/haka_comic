import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:haka_comic/database/local_favorites_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class FolderComics extends StatefulWidget {
  const FolderComics({super.key, required this.folder});

  final LocalFolder? folder;

  @override
  State<FolderComics> createState() => _FolderComicsState();
}

class _FolderComicsState extends State<FolderComics> with RequestMixin {
  final _helper = LocalFavoritesHelper();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isSearching = false;
  String _keyword = '';

  late final _getFolderComicsHandler = _helper.getFolderComics.useRequest(
    manual: true,
    onSuccess: (comics, _) {
      Log.i('Get folder comics success', comics.toString());
    },
    onError: (e, _) {
      Log.e('Get folder comics error', error: e);
    },
  );

  Future<void> removeComic(String cid) async {
    if (widget.folder == null) return;
    await _helper.removeComicFromFolder(cid, widget.folder!.id);
  }

  List<HistoryDoc> cachedComics = [];
  late final _removeComicHandler = removeComic.useRequest(
    manual: true,
    onBefore: (cid) {
      final comics = _getFolderComicsHandler.state.data ?? [];
      cachedComics = comics;
      _getFolderComicsHandler.mutate(
        comics.where((c) => c.uid != cid).toList(),
      );
    },
    onSuccess: (_, cid) {
      Log.i('Remove comic from folder success', cid);
    },
    onError: (e, _) {
      Log.e('Remove comic from folder error', error: e);
      Toast.show(message: '移除失败');
      _getFolderComicsHandler.mutate(cachedComics);
    },
  );

  final entries = <ContextMenuEntry>[
    MenuItem(
      label: Text(
        '复制标题',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.copy),
      value: 'copy',
    ),
    MenuItem(
      label: Text(
        '移除漫画',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.delete),
      value: 'delete',
    ),
  ];

  late final menu = ContextMenu(entries: entries, padding: const .all(8.0));

  void _onItemSelected(dynamic key, ComicBase item) async {
    switch (key) {
      case 'copy':
        final title = item.title;
        await Clipboard.setData(ClipboardData(text: title));
        Toast.show(message: '已复制');
        break;
      case 'delete':
        _removeComicHandler.run(item.uid);
        break;
    }
  }

  @override
  List<RequestHandler> registerHandler() => [
    _getFolderComicsHandler,
    _removeComicHandler,
  ];

  @override
  initState() {
    super.initState();
    _getFolderComicsHandler.run(widget.folder?.id);
  }

  @override
  didUpdateWidget(covariant FolderComics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.folder?.id != oldWidget.folder?.id) {
      _getFolderComicsHandler.run(widget.folder?.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _keyword = '';
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  void _clearKeyword() {
    if (_keyword.trim().isEmpty) return;
    setState(() {
      _keyword = '';
      _searchController.clear();
    });
    _searchFocusNode.requestFocus();
  }

  List<ComicBase> _filterComics(List<ComicBase> comics) {
    final keyword = _keyword.trim();
    if (keyword.isEmpty) return comics;

    final k = keyword.toLowerCase();
    bool contains(String value) => value.toLowerCase().contains(k);

    return comics.where((e) {
      if (contains(e.title)) return true;
      if (e.author.isNotEmpty && contains(e.author)) return true;
      if (e.tags.any(contains)) return true;
      if (e.categories.any(contains)) return true;
      return false;
    }).toList();
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      child: _isSearching
          ? Row(
              spacing: 5,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: '返回',
                  onPressed: _closeSearch,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: '搜索标题/作者/标签',
                      border: const OutlineInputBorder(),
                      suffixIcon: _keyword.trim().isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: '清空',
                              onPressed: _clearKeyword,
                            ),
                    ),
                    onChanged: (value) {
                      setState(() => _keyword = value);
                    },
                  ),
                ),
              ],
            )
          : Row(
              spacing: 5,
              children: [
                Text(
                  '收藏夹:${widget.folder?.name ?? '全部'}',
                  style: context.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '搜索',
                  onPressed: _openSearch,
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_getFolderComicsHandler.state) {
      Success(:final data) => () {
        if (data.isEmpty) return const Empty();

        final filtered = _filterComics(data);
        return Column(
          children: [
            _header(context),
            Expanded(
              child: filtered.isEmpty
                  ? const Empty()
                  : CommonTMIList(
                      onItemSelected: widget.folder == null
                          ? null
                          : _onItemSelected,
                      contextMenu: widget.folder == null ? null : menu,
                      comics: filtered,
                    ),
            ),
          ],
        );
      }(),
      Error(:final error) => ErrorPage(
        errorMessage: error.toString(),
        onRetry: _getFolderComicsHandler.refresh,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
