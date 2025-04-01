import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
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

class _FavoritesState extends State<Favorites>
    with AutomaticKeepAliveClientMixin {
  final _handler = fetchFavoriteComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch favorite comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch favorite comics error', e);
    },
  );

  int _page = 1;
  // 漫画排序方式应该是失效了
  final ComicSortType _sortType = ComicSortType.dd;

  @override
  void initState() {
    _handler
      ..addListener(_update)
      ..run(UserFavoritePayload(page: _page, sort: _sortType));

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = context.width;
    final pages = _handler.data?.comics.pages ?? 1;
    final comics = _handler.data?.comics.docs ?? [];

    return BasePage(
      isLoading: _handler.isLoading,
      onRetry: _handler.refresh,
      error: _handler.error,
      child: Stack(
        children: [
          Positioned.fill(
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
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _onPageChange(1),
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
