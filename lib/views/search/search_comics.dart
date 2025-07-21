import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
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
    with AutoRegisterHandlerMixin {
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

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.keyword;

    _handler.run(
      SearchPayload(keyword: widget.keyword, page: _page, sort: _sortType),
    );
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

  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  @override
  Widget build(BuildContext context) {
    final pages = _handler.data?.comics.pages ?? 0;
    final comics = _handler.data?.comics.docs ?? [];

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
                final key = ValueKey(comics[index].id);
                return isSimpleMode
                    ? SimpleSearchListItem(comic: comics[index], key: key)
                    : SearchListItem(comic: comics[index], key: key);
              },
              itemCount: comics.length,
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
    setState(() {
      _sortType = type;
      _page = 1;
    });
    _handler.run(
      SearchPayload(keyword: _searchController.text, page: 1, sort: type),
    );
  }
}
