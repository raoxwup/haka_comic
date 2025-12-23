import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/providers/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_type_selector.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:provider/provider.dart';

class SearchComics extends StatefulWidget {
  const SearchComics({super.key, required this.keyword});

  final String keyword;

  @override
  State<SearchComics> createState() => _SearchComicsState();
}

class _SearchComicsState extends State<SearchComics>
    with RequestMixin, PaginationMixin {
  final _searchController = TextEditingController();

  late final _handler = searchComics.useRequest(
    defaultParams: SearchPayload(
      keyword: widget.keyword,
      page: _page,
      sort: _sortType,
    ),
    onSuccess: (data, _) {
      Log.info('Search comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Search comics error', e);
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

  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Future<void> loadMore() async {
    final pages = _handler.state.data?.comics.pages ?? 1;
    if (_page >= pages) return;
    await _onPageChange(_page + 1);
  }

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.keyword;
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
          body: switch (_handler.state) {
            RequestState(:final data) when data != null => CommonTMIList(
              controller: pagination ? null : scrollController,
              comics: context.filtered(data.comics.docs),
              pageSelectorBuilder: pagination
                  ? (context) => PageSelector(
                      currentPage: _page,
                      pages: data.comics.pages,
                      onPageChange: _onPageChange,
                    )
                  : null,
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

  void _buildSortTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => SortTypeSelector(
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
    });
    _handler.run(
      SearchPayload(keyword: _searchController.text, page: 1, sort: type),
    );
  }
}
