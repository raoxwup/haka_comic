import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/mixin/pagination_handler.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/tmi_list.dart';
import 'package:haka_comic/views/search/search_list_item.dart';
import 'package:haka_comic/views/search/simple_search_list_item.dart';
import 'package:haka_comic/views/comics/sort_type_selector.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:provider/provider.dart';

class SearchComics extends StatefulWidget {
  const SearchComics({super.key, required this.keyword});

  final String keyword;

  @override
  State<SearchComics> createState() => _SearchComicsState();
}

class _SearchComicsState extends State<SearchComics>
    with AutoRegisterHandlerMixin, PaginationHandlerMixin {
  final _searchController = TextEditingController();

  late final _handler = searchComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Search comics success', data.toString());
      setState(() {
        if (!pagination) {
          _comics.addAll(data.comics.docs);
        } else {
          _comics = data.comics.docs;
        }
      });
    },
    onError: (e, _) {
      Log.error('Search comics error', e);
    },
  );

  List<SearchComic> _comics = [];
  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  Future<void> loadMore() async {
    final pages = _handler.data?.comics.pages ?? 1;
    if (_page >= pages) return;
    await _onPageChange(_page + 1);
  }

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.keyword;

    _handler.run(
      SearchPayload(keyword: widget.keyword, page: _page, sort: _sortType),
    );
  }

  Future<void> _onPageChange(int page) async {
    setState(() {
      _page = page;
    });
    await _handler.run(
      SearchPayload(
        keyword: _searchController.text,
        page: _page,
        sort: _sortType,
      ),
    );
  }

  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  @override
  Widget build(BuildContext context) {
    final pages = _handler.data?.comics.pages ?? 1;

    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
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
                  icon: const Icon(Icons.close),
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
          body:
              pagination
                  ? BasePage(
                    isLoading: _handler.isLoading || !completed,
                    error: _handler.error,
                    onRetry: _handler.refresh,
                    child: TMIList(
                      pageSelectorBuilder: (context) {
                        return PageSelector(
                          currentPage: _page,
                          pages: pages,
                          onPageChange: _onPageChange,
                        );
                      },
                      itemBuilder: (context, index) {
                        final key = ValueKey(_comics[index].id);
                        return isSimpleMode
                            ? SimpleSearchListItem(
                              comic: _comics[index],
                              key: key,
                            )
                            : SearchListItem(comic: _comics[index], key: key);
                      },
                      itemCount: _comics.length,
                    ),
                  )
                  : BasePage(
                    isLoading: false,
                    error: _handler.error,
                    onRetry: _handler.refresh,
                    child: TMIList(
                      controller: scrollController,
                      itemCount: _comics.length,
                      itemBuilder: (context, index) {
                        final key = ValueKey(_comics[index].id);
                        return isSimpleMode
                            ? SimpleSearchListItem(
                              comic: _comics[index],
                              key: key,
                            )
                            : SearchListItem(comic: _comics[index], key: key);
                      },
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
    if (type == _sortType) return;
    setState(() {
      _sortType = type;
      _page = 1;
      _comics = [];
    });
    _handler.run(
      SearchPayload(keyword: _searchController.text, page: 1, sort: type),
    );
  }
}
