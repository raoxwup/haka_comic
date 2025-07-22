import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/mixin/pagination_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites>
    with AutoRegisterHandlerMixin, PaginationHandlerMixin {
  late final _handler = fetchFavoriteComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch favorite comics success', data.toString());
      setState(() {
        if (!pagination) {
          _comics.addAll(data.comics.docs);
        } else {
          _comics = data.comics.docs;
        }
      });
    },
    onError: (e, _) {
      Log.error('Fetch favorite comics error', e);
    },
  );

  List<Doc> _comics = [];
  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  @override
  void initState() {
    super.initState();
    _handler.run(UserFavoritePayload(page: _page, sort: _sortType));
  }

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  Future<void> loadMore() async {
    final pages = _handler.data?.comics.pages ?? 1;
    if (_page >= pages) return;
    await _onPageChange(_page + 1);
  }

  Future<void> _onPageChange(int page) async {
    setState(() {
      _page = page;
    });
    await _handler.run(UserFavoritePayload(page: page, sort: _sortType));
  }

  void _onSortChange(ComicSortType sortType) {
    if (sortType == _sortType) return;
    setState(() {
      _page = 1;
      _sortType = sortType;
      _comics = [];
    });
    _handler.run(UserFavoritePayload(page: 1, sort: sortType));
  }

  @override
  Widget build(BuildContext context) {
    final pages = _handler.data?.comics.pages ?? 1;

    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('收藏漫画'),
            actions: [
              IconButton(
                tooltip: '刷新',
                onPressed: () => _onPageChange(1),
                icon: const Icon(Icons.refresh),
              ),
              MenuAnchor(
                menuChildren: <Widget>[
                  ...[
                    {'label': '新到旧', 'type': ComicSortType.dd},
                    {'label': '旧到新', 'type': ComicSortType.da},
                  ].map(
                    (e) => MenuItemButton(
                      onPressed: () {
                        _onSortChange(e['type'] as ComicSortType);
                      },
                      child: Row(
                        spacing: 5,
                        children: [
                          Text(e['label'] as String),
                          if (_sortType == e['type'])
                            Icon(
                              Icons.done,
                              size: 16,
                              color: context.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                builder: (_, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.sort),
                    tooltip: '排序',
                  );
                },
              ),
            ],
          ),
          body:
              pagination
                  ? BasePage(
                    isLoading: _handler.isLoading,
                    onRetry: _handler.refresh,
                    error: _handler.error,
                    child: CommonTMIList(
                      comics: _comics,
                      pageSelectorBuilder: (context) {
                        return PageSelector(
                          currentPage: _page,
                          pages: pages,
                          onPageChange: _onPageChange,
                        );
                      },
                    ),
                  )
                  : BasePage(
                    isLoading: false,
                    onRetry: _handler.refresh,
                    error: _handler.error,
                    child: CommonTMIList(
                      comics: _comics,
                      controller: scrollController,
                      footerBuilder: (context) {
                        final loading = _handler.isLoading;
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child:
                                  loading
                                      ? CircularProgressIndicator(
                                        constraints: BoxConstraints.tight(
                                          const Size(28, 28),
                                        ),
                                        strokeWidth: 3,
                                      )
                                      : Text(
                                        '没有更多数据了',
                                        style: context.textTheme.bodySmall,
                                      ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        );
      },
    );
  }
}
