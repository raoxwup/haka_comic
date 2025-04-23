import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/search_list_item.dart';
import 'package:haka_comic/views/comics/sort_type_selector.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:provider/provider.dart';

class SearchComics extends StatefulWidget {
  const SearchComics({super.key, required this.keyword});

  final String keyword;

  @override
  State<SearchComics> createState() => _SearchComicsState();
}

class _SearchComicsState extends State<SearchComics> {
  final _searchController = TextEditingController();

  final _handler = searchComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Search comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Search comics error', e);
    },
  );

  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  void _update() => setState(() {});

  @override
  void initState() {
    _searchController.text = widget.keyword;

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

  void _onPageChange(int page) {
    setState(() {
      _page = page;
    });
    _handler.run(
      SearchPayload(
        keyword: _searchController.text,
        page: _page,
        sort: _sortType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    final pages = _handler.data?.comics.pages ?? 0;
    final comics = _handler.data?.comics.docs ?? [];

    return RouteAwarePageWrapper(
      onRouteAnimationCompleted: () {
        _handler.run(
          SearchPayload(keyword: widget.keyword, page: _page, sort: _sortType),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '搜索',
              border: InputBorder.none,
              suffixIcon: IconButton(
                onPressed: () {
                  if (_searchController.text.isEmpty) {
                    context.pop();
                  } else {
                    _searchController.clear();
                  }
                },
                icon: Icon(Icons.close),
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.read<SearchProvider>().add(value);
                _onPageChange(1);
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: '排序',
              icon: const Icon(Icons.sort),
              onPressed: _buildSortTypeSelector,
            ),
          ],
        ),
        body: BasePage(
          isLoading: _handler.isLoading,
          error: _handler.error,
          onRetry: _handler.refresh,
          child: CustomScrollView(
            slivers: [
              PageSelector(
                currentPage: _page,
                pages: pages,
                onPageChange: _onPageChange,
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
                  return SearchListItem(comic: comics[index]);
                },
                itemCount: comics.length,
              ),
              PageSelector(
                currentPage: _page,
                pages: pages,
                onPageChange: _onPageChange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buildSortTypeSelector() {
    showDialog(
      context: context,
      builder:
          (context) => SortTypeSelector(
            sortType: _sortType,
            onSortTypeChange: _onSortTypeChange,
          ),
    );
  }

  void _onSortTypeChange(ComicSortType type) {
    setState(() {
      _sortType = type;
      _page = 1;
    });
    _handler.run(
      SearchPayload(keyword: _searchController.text, page: 1, sort: type),
    );
  }
}
