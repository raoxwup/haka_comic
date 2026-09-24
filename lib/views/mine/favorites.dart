import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/mixin/batch_select.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/widgets/error_page.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites>
    with RequestMixin, PaginationMixin, BatchSelectMixin {
  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  late final _handler = fetchFavoriteComics.useRequest(
    defaultParams: UserFavoritePayload(page: _page, sort: _sortType),
    onSuccess: (data, _) {
      Log.i('Fetch favorite comics success', data.toString());
    },
    onError: (e, _) {
      Log.e('Fetch favorite comics error', error: e);
    },
    reducer: pagination
        ? null
        : (prev, current) {
            if (prev == null) return current;
            return current.copyWith.comics(
              docs: [...prev.comics.docs, ...current.comics.docs],
            );
          },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Future<void> loadMore() async {
    final pages = _handler.state.data?.comics.pages ?? 1;
    if (_page >= pages) return;
    await _onPageChange(_page + 1);
  }

  Future<void> _onPageChange(int page) async {
    setState(() {
      _page = page;
      isSelecting = false;
      selectedCids = {};
    });
    await _handler.run(UserFavoritePayload(page: page, sort: _sortType));
  }

  void _onSortChange(ComicSortType sortType) {
    if (sortType == _sortType) return;
    setState(() {
      _page = 1;
      _sortType = sortType;
      isSelecting = false;
      selectedCids = {};
    });
    _handler.mutate(ComicsResponse.empty);
    _handler.run(UserFavoritePayload(page: 1, sort: sortType));
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwarePageWrapper(
      builder: (context, completed) {
        final data = _handler.state.data;
        final comics = data?.comics.docs ?? [];

        return Scaffold(
          appBar: isSelecting
              ? _SelectionAppBar(
                  count: selectedCids.length,
                  onExit: exitSelectionMode,
                  onSelectAll: () => selectAll(comics),
                  onInvert: () => invertSelection(comics),
                )
              : _NormalAppBar(
                  sortType: _sortType,
                  isDownloading: isDownloading,
                  onSortChange: _onSortChange,
                ),
          body: Stack(
            children: [
              switch (_handler.state) {
                RequestState(:final data) when data != null => CommonTMIList(
                  comics: data.comics.docs,
                  selectedCids: isSelecting ? selectedCids : null,
                  onItemLongPress: (comic) {
                    if (!isSelecting) enterSelectionMode(comic.uid);
                  },
                  onItemSelected: isSelecting
                      ? (_, comic) => toggleItem(comic.uid)
                      : null,
                  enableDefaultGestures: !isSelecting,
                  pageSelectorBuilder: pagination
                      ? (context) {
                          return PageSelector(
                            currentPage: _page,
                            pages: data.comics.pages,
                            onPageChange: isDownloading
                                ? (_) async {}
                                : _onPageChange,
                          );
                        }
                      : null,
                  controller: pagination ? null : scrollController,
                  footerBuilder: pagination
                      ? null
                      : (context) {
                          final loading = _handler.state.loading;
                          return CommonPaginationFooter(loading: loading);
                        },
                ),
                Error(:final error) => ErrorPage(
                  errorMessage: error.toString(),
                  onRetry: _handler.refresh,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
              if (isSelecting && selectedCids.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: FilledButton(
                    onPressed: isDownloading ? null : () => batchDownload(comics),
                    child: isDownloading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('批量下载(${selectedCids.length})'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SelectionAppBar({
    required this.count,
    required this.onExit,
    required this.onSelectAll,
    required this.onInvert,
  });

  final int count;
  final VoidCallback onExit;
  final VoidCallback onSelectAll;
  final VoidCallback onInvert;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('已选 $count 项'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '退出选择',
        onPressed: onExit,
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: '全选',
          onPressed: onSelectAll,
        ),
        IconButton(
          icon: const Icon(Icons.repeat),
          tooltip: '反选',
          onPressed: onInvert,
        ),
      ],
    );
  }
}

class _NormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _NormalAppBar({
    required this.sortType,
    required this.isDownloading,
    required this.onSortChange,
  });

  final ComicSortType sortType;
  final bool isDownloading;
  final void Function(ComicSortType) onSortChange;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('收藏漫画'),
      actions: [
        MenuAnchor(
          menuChildren: [
            {'label': '新到旧', 'type': ComicSortType.dd},
            {'label': '旧到新', 'type': ComicSortType.da},
          ].map((e) => MenuItemButton(
            onPressed: isDownloading ? null : () => onSortChange(e['type'] as ComicSortType),
            child: Row(
              spacing: 5,
              children: [
                Text(e['label'] as String),
                if (sortType == e['type'])
                  Icon(Icons.done, size: 16, color: context.colorScheme.primary),
              ],
            ),
          )).toList(),
          builder: (_, controller, _) => IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
      ],
    );
  }
}
