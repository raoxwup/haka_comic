import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/providers/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/boolean_parser.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_and_filter_toolbar.dart';
import 'package:haka_comic/views/search/boolean_search.dart';
import 'package:haka_comic/views/search/search_cache.dart';
import 'package:haka_comic/views/search/search_probe.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/utils/chinese_converter.dart';
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

  /// API 请求 handler（UI 状态载体：loading / data / error）
  late final _handler = searchComics.useRequest(
    manual: true,
    defaultParams: SearchPayload(
      keyword: widget.keyword,
      page: _page,
      sort: _sortType,
    ),
    onSuccess: (data, _) {
      Log.i('Search comics success', data.toString());
    },
    onError: (e, _) {
      Log.e('Search comics error', error: e);
    },
    reducer: (prev, current) {
      if (!_hasBoolOps && pagination) return current;
      if (prev == null) return current;
      return current.copyWith.comics(
        docs: [...prev.comics.docs, ...current.comics.docs],
      );
    },
  );

  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;
  List<String> _selectedCategories = [];

  /// 布尔搜索引擎（仅布尔模式下创建）
  BooleanSearchEngine? _engine;

  SearchQuery _currentQuery = const SearchQuery();

  bool get _hasBoolOps =>
      AppConf().enableBooleanSearch &&
      (_currentQuery.andWords.isNotEmpty || _currentQuery.notWords.isNotEmpty);

  /// 根据设置规范化搜索词（简繁转换）
  String _normalizeKeyword(String keyword) {
    final mode = AppConf().searchNormalization;
    if (mode == 'off') return keyword;
    if (mode == 's2t') return ChineseConverter.instance.toTraditional(keyword);
    return ChineseConverter.instance.toSimplified(keyword);
  }

  @override
  List<RequestHandler> registerHandler() => [_handler];

  // ═══════════════════════════════════════
  // 搜索逻辑
  // ═══════════════════════════════════════

  /// 统一搜索入口
  /// [silent] 为 true 时仅写入缓存，不更新 UI（用于预加载）
  Future<void> _performSearch({int? page, bool silent = false, bool forceRefresh = false}) async {
    final targetPage = page ?? 1;
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    _currentQuery = AppConf().enableBooleanSearch
        ? parseSearchQuery(keyword)
        : const SearchQuery();

    Log.d('Search entry',
      'keyword="$keyword" page=$targetPage silent=$silent '
      'hasBoolOps=$_hasBoolOps sort=$_sortType');

    if (!_hasBoolOps) {
      // ── 非布尔模式 ─────────
      if (targetPage == 1 && !silent) _handler.resetState();
      if (!silent) _page = targetPage;
      final kw = _normalizeKeyword(keyword);
      final cacheKey = SearchCache.buildKey(kw, _sortType, _selectedCategories);

      if (page == null) {
        // ── 搜索入口：先请求 page1 校验缓存鲜度 ─────────
        await _handler.run(SearchPayload(
          keyword: kw, page: 1, sort: _sortType, categories: _selectedCategories,
        ));
        if (!_handler.state.hasData) return;
        final fresh = _handler.state.data!;
        if (SearchCache.validateFreshness(cacheKey, fresh)) {
          SearchCache.touch(cacheKey);
          if (!silent) _handler.mutate(fresh);
        } else {
          SearchCache.remove(cacheKey);
          SearchCache.put(cacheKey, 1, fresh);
          SearchCache.touch(cacheKey);
          SearchProbeCache.put(kw, _selectedCategories, fresh.comics.total);
          if (!silent) _handler.mutate(fresh);
        }
      } else {
        // ── 翻页：缓存命中直接用，miss 正常请求 ─────────
        final cached = forceRefresh ? null : SearchCache.get(cacheKey, targetPage);
        if (cached != null) {
          if (!silent) _handler.mutate(cached);
          SearchCache.touch(cacheKey);
        } else {
          await _handler.run(SearchPayload(
            keyword: kw, page: targetPage, sort: _sortType, categories: _selectedCategories,
          ));
          if (_handler.state.hasData) {
            SearchCache.put(cacheKey, targetPage, _handler.state.data!);
            SearchCache.touch(cacheKey);
          }
        }
      }
      return;
    }

    // ── 布尔模式：委托引擎 ─────────
    if (!silent) _page = targetPage;
    if (targetPage == 1 && !silent) {
      _handler.resetState();
      // 统一进入 Loading 状态，确保 UI 显示加载指示器
      // 非布尔模式通过 _handler.run() 内部自动调 setup()
      // 布尔模式手动调一次，保持一致
      _handler.setup(SearchPayload(
        keyword: keyword, page: 1, sort: _sortType, categories: _selectedCategories,
      ));
    }

    final engine = BooleanSearchEngine(
      query: _currentQuery,
      sortType: _sortType,
      categories: _selectedCategories,
      normalizeKeyword: _normalizeKeyword,
      onResults: (_) {},
    );
    engine.onResults = (results) {
      final resp = engine.responseWithResults();
      if (resp != null) _handler.mutate(resp);
    };
    _engine = engine;

    final resp = targetPage == 1
        ? await engine.searchFirstPage()
        : await engine.searchNextPage(targetPage);

    // 检查引擎是否仍为当前（防止旧引擎的结果覆盖新搜索）
    if (!identical(_engine, engine)) return;

    if (resp != null && !silent) {
      _handler.mutate(resp);
    }
  }

  @override
  Future<void> loadMore() async {
    if (_engine?.isAutoFilling ?? false) return;
    final pages = _handler.state.data?.comics.pages ?? 1;

    if (_hasBoolOps && _engine != null) {
      await _engine!.loadMore(pages);
      if (!mounted) return;
      final resp = _engine!.responseWithResults();
      if (resp != null) _handler.mutate(resp);
      _page = _engine!.nextServerPage - 1;
    } else {
      final nextPage = _page + 1;
      if (nextPage > pages) return;
      await _performSearch(page: nextPage);
    }
  }

  // ═══════════════════════════════════════
  // 生命周期
  // ═══════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    if (_hasBoolOps && pagination) {
      scrollController.addListener(onScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
  }

  @override
  void dispose() {
    if (_hasBoolOps && pagination) {
      scrollController.removeListener(onScroll);
    }
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // 翻页
  // ═══════════════════════════════════════

  Future<void> _onPageChange(int page) async {
    _handler.resetState();
    _page = page;
    if (scrollController.hasClients) scrollController.jumpTo(0);
    await _performSearch(page: page);
  }

  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  // ═══════════════════════════════════════
  // UI
  // ═══════════════════════════════════════

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
                  _performSearch();
                }
              },
            ),
            actions: [
              ...SortAndFilterToolbar(
                sortType: _sortType,
                selectedCategories: _selectedCategories,
                onSortTypeChange: _onSortTypeChange,
                onCategoriesChange: _onCategoriesChange,
              ).buildButtons(context),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() => _buildRealtimeBody();

  Widget _buildRealtimeBody() {
    final showPageSelector = pagination && !_hasBoolOps;
    if (_handler.state.loading && _handler.state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // 布尔模式：页 1 过滤为 0 但 autoFill 正在扫描后续页 → 显示加载态
    if (_hasBoolOps &&
        _handler.state.data != null &&
        _handler.state.data!.comics.docs.isEmpty &&
        (_engine?.isAutoFilling ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (_handler.state) {
      RequestState(:final data) when data != null => CommonTMIList(
        controller: showPageSelector ? null : scrollController,
        comics: context.filtered(data.comics.docs),
        emptyRefreshCallback: () => _performSearch(page: _page, forceRefresh: true),
        pageSelectorBuilder: showPageSelector
            ? (context) => PageSelector(
                currentPage: _page,
                pages: data.comics.pages,
                onPageChange: _onPageChange,
              )
            : null,
        footerBuilder: showPageSelector
            ? null
            : (context) {
                final loading =
                    _handler.state.loading || (_engine?.isAutoFilling ?? false);
                return CommonPaginationFooter(loading: loading);
              },
      ),
      Error(:final error) => ErrorPage(
        errorMessage: error.toString(),
        onRetry: _handler.refresh,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  // ═══════════════════════════════════════
  // 筛选/排序变更
  // ═══════════════════════════════════════

  void _onCategoriesChange(List<String> categories) {
    setState(() {
      _selectedCategories = categories;
      _page = 1;
    });
    _performSearch();
  }

  void _onSortTypeChange(ComicSortType type) {
    if (type == _sortType) return;
    setState(() {
      _sortType = type;
      _page = 1;
    });
    _performSearch();
  }
}