import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/mixin/blocked_words.dart';
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
    with AutoRegisterHandlerMixin, PaginationHandlerMixin, BlockedWordsMixin {
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
          body: BasePage(
            isLoading: pagination ? (_handler.isLoading || !completed) : false,
            error: _handler.error,
            onRetry: _handler.refresh,
            child: _buildList(pagination),
          ),
        );
      },
    );
  }

  Widget _buildList(bool pagination) {
    final pages = _handler.data?.comics.pages ?? 1;
    return TMIList(
      controller: pagination ? null : scrollController,
      itemCount: _comics.length,
      itemBuilder: _buildItem,
      pageSelectorBuilder:
          pagination
              ? (context) => PageSelector(
                currentPage: _page,
                pages: pages,
                onPageChange: _onPageChange,
              )
              : null,
      footerBuilder:
          pagination
              ? null
              : (context) {
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
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _comics[index];
    final key = ValueKey(item.id);

    // 屏蔽逻辑
    final tag = item.tags.firstWhereOrNull((t) => blockedTags.contains(t));
    final category = item.categories.firstWhereOrNull(
      (c) => AppConf().blacklist.contains(c),
    );
    final word = blockedWords.firstWhereOrNull((w) => item.title.contains(w));
    final blocked = category ?? tag ?? word;

    return isSimpleMode
        ? SimpleSearchListItem(comic: item, key: key, blockedWords: blocked)
        : SearchListItem(comic: item, key: key, blockedWords: blocked);
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
