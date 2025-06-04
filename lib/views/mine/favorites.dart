import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final _handler = fetchFavoriteComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch favorite comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch favorite comics error', e);
    },
  );

  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  @override
  void initState() {
    _handler.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    _handler
      ..removeListener(_update)
      ..dispose();

    super.dispose();
  }

  void _update() => setState(() {});

  void _onPageChange(int page) {
    setState(() {
      _page = page;
    });
    _handler.run(UserFavoritePayload(page: page, sort: _sortType));
  }

  void _onSortChange(ComicSortType sortType) {
    if (sortType == _sortType) return;
    setState(() {
      _page = 1;
      _sortType = sortType;
    });
    _handler.run(UserFavoritePayload(page: 1, sort: sortType));
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    final pages = _handler.data?.comics.pages ?? 1;
    final comics = _handler.data?.comics.docs ?? [];

    return RouteAwarePageWrapper(
      onRouteAnimationCompleted:
          () => _handler.run(UserFavoritePayload(page: _page, sort: _sortType)),
      child: Scaffold(
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
                );
              },
            ),
          ],
        ),
        body: BasePage(
          isLoading: _handler.isLoading,
          onRetry: _handler.refresh,
          error: _handler.error,
          child: CustomScrollView(
            slivers: [
              PageSelector(
                pages: pages,
                onPageChange: _onPageChange,
                currentPage: _page,
              ),
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent:
                      UiMode.m1(context)
                          ? width
                          : UiMode.m2(context)
                          ? width / 2
                          : width / 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  return ListItem(doc: comics[index]);
                },
                itemCount: comics.length,
              ),
              PageSelector(
                pages: pages,
                onPageChange: _onPageChange,
                currentPage: _page,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
