import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart' hide UseRequest1Extensions;
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
    with RequestMixin, PaginationMixin {
  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  late final _handler = fetchFavoriteComics.useRequest(
    defaultParams: UserFavoritePayload(page: _page, sort: _sortType),
    onSuccess: (data, _) {
      Log.info('Fetch favorite comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch favorite comics error', e);
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
    });
    await _handler.run(UserFavoritePayload(page: page, sort: _sortType));
  }

  void _onSortChange(ComicSortType sortType) {
    if (sortType == _sortType) return;
    setState(() {
      _page = 1;
      _sortType = sortType;
    });
    _handler.mutate(ComicsResponse.empty);
    _handler.run(UserFavoritePayload(page: 1, sort: sortType));
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('收藏漫画'),
            actions: [
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
          body: switch (_handler.state) {
            RequestState(:final data) when data != null => CommonTMIList(
              comics: data.comics.docs,
              pageSelectorBuilder: pagination
                  ? (context) {
                      return PageSelector(
                        currentPage: _page,
                        pages: data.comics.pages,
                        onPageChange: _onPageChange,
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
        );
      },
    );
  }
}
