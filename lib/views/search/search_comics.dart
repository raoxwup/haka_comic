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
import 'package:haka_comic/utils/search_filter.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_and_filter_toolbar.dart';
import 'package:haka_comic/views/search/search_cache.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:opencc/opencc.dart';
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

  /// 简繁转换器（按需创建，模式变更时自动重建）
  ZhConverter? _zhConverter;
  String _lastNormalizationMode = 'off';

  /// 实时模式 handler（仅用于 API 请求，manual 模式由 _performSearch 触发）
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
    // 有布尔运算符 → 强制追加（无论 pagination 设置）
    // 无布尔运算符 → 按 pagination 设置
    reducer: (prev, current) {
      if (!_hasBoolOps && pagination) return current; // 分页替换
      if (prev == null) return current;
      return current.copyWith.comics(
        docs: [...prev.comics.docs, ...current.comics.docs],
      );
    },
  );

  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;
  List<String> _selectedCategories = [];
  SearchQuery _currentQuery = const SearchQuery();

  // 填充式加载状态
  int _nextServerPage = 1;
  bool _autoFilling = false;

  bool get _hasBoolOps =>
      AppConf().enableBooleanSearch &&
      (_currentQuery.andWords.isNotEmpty || _currentQuery.notWords.isNotEmpty);

  /// 客户端布尔过滤：按 andWords/notWords 过滤 API 返回结果
  List<SearchComic> _applyBooleanFilter(
    List<SearchComic> docs,
    SearchQuery query,
  ) => applyBooleanFilter(docs, query);

  /// 根据设置规范化搜索词（简繁转换）
  String _normalizeKeyword(String keyword) {
    final mode = AppConf().searchNormalization;
    if (mode == 'off') return keyword;
    if (_lastNormalizationMode != mode) {
      _zhConverter?.dispose();
      _zhConverter = null;
      _lastNormalizationMode = mode;
    }
    _zhConverter ??= ZhConverter(mode);
    return _zhConverter!.convert(keyword);
  }



  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Future<void> loadMore() async {
    final pages = _handler.state.data?.comics.pages ?? 1;
    // 有布尔运算符时用 _nextServerPage（autoFill 可能已请求过后续页）
    final nextPage = _hasBoolOps ? _nextServerPage : _page + 1;
    if (nextPage > pages) return;
    await _performSearch(page: nextPage);
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
  }

  @override
  void dispose() {
    _autoFilling = false;
    _zhConverter?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 统一搜索入口
  Future<void> _performSearch({int? page}) async {
    final targetPage = page ?? 1;
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // 新搜索取消前一次自动填充
    _autoFilling = false;

    _currentQuery = AppConf().enableBooleanSearch
        ? parseSearchQuery(keyword)
        : const SearchQuery();

    // 连续两次无匹配则清空全部缓存
    SearchCache.checkAndClearStale();

    // 新搜索（第1页）时清除旧数据，防止 reducer 追加
    if (targetPage == 1) _handler.resetState();
    setState(() => _page = targetPage);
    await _performRealtimeSearch(targetPage);
  }

  // ═══════════════════════════════════════
  // 搜索请求
  // ═══════════════════════════════════════

  Future<void> _performRealtimeSearch(int page) async {
    // 有布尔运算符时用 firstServerKeyword 发给 API
    final serverKeyword =
        _hasBoolOps
            ? (_currentQuery.firstServerKeyword ?? _searchController.text)
            : _searchController.text;
    final normalizedKeyword = _normalizeKeyword(serverKeyword);
    final cacheKey = SearchCache.buildKey(
      normalizedKeyword,
      _sortType,
      _selectedCategories,
    );

    // 查 API 缓存
    final cached = SearchCache.get(cacheKey, page);
    if (cached != null) {
      _handler.mutate(cached);
      SearchCache.markHit();
    } else {
      // 发起网络请求
      final payload = SearchPayload(
        keyword: normalizedKeyword,
        page: page,
        sort: _sortType,
        categories: _selectedCategories,
      );
      await _handler.run(payload);

      if (_handler.state.hasData) {
        final fresh = _handler.state.data!;

        if (page == 1) {
          if (SearchCache.validateFreshness(cacheKey, fresh)) {
            // 数据未变，复用所有缓存页
            SearchCache.markHit();
            SearchCache.put(cacheKey, 1, fresh);
            final pages = SearchCache.getCachedPages(cacheKey);
            if (pages.length > 1) {
              pages.sort();
              final farthest = SearchCache.get(cacheKey, pages.last);
              if (farthest != null) _handler.mutate(farthest);
            }
          } else {
            // 数据已变，清除该条件的旧缓存，重新缓存
            SearchCache.remove(cacheKey);
            SearchCache.put(cacheKey, 1, fresh);
            SearchCache.markMiss();
          }
        } else {
          SearchCache.put(cacheKey, page, fresh);
        }
      }
    }

    // 有布尔运算符时，用过滤后的结果替换 handler 中的数据
    if (_hasBoolOps && _handler.state.hasData) {
      final raw = _handler.state.data!;
      final filtered = _applyBooleanFilter(raw.comics.docs, _currentQuery);
      _handler.mutate(
        raw.copyWith.comics(docs: filtered, total: filtered.length),
      );
    }

    // 有布尔运算符且过滤后不足 20 条，启动自动填充
    if (_hasBoolOps && page == 1) {
      final currentCount = _handler.state.data?.comics.docs.length ?? 0;
      final totalPages = _handler.state.data?.comics.pages ?? 0;
      if (currentCount < 20 && totalPages > 1) {
        _nextServerPage = 2;
        _autoFillResults(totalPages);
      }
    }
  }

  /// 自动填充：布尔过滤后结果不足时，并发请求后续页补充
  Future<void> _autoFillResults(int totalPages) async {
    _autoFilling = true;
    final batchSize = AppConf().maxRequestsPerSecond;
    const maxAutoPages = 10; // 安全上限

    // 预计算需要请求的页码列表
    final pagesToFetch = <int>[];
    for (int p = _nextServerPage;
        p <= totalPages && pagesToFetch.length < maxAutoPages;
        p++) {
      pagesToFetch.add(p);
    }

    // 按 batchSize 分批并发
    for (int i = 0;
        i < pagesToFetch.length && _autoFilling && mounted;
        i += batchSize) {
      final batch = pagesToFetch.skip(i).take(batchSize);

      final normalizedKw = _normalizeKeyword(
        _currentQuery.firstServerKeyword ?? _searchController.text,
      );
      final cacheKey = SearchCache.buildKey(
        normalizedKw,
        _sortType,
        _selectedCategories,
      );
      final results = await Future.wait<SearchResponse?>(batch.map((
        page,
      ) async {
        final cached = SearchCache.get(cacheKey, page);
        if (cached != null) {
          return cached;
        }
        final payload = SearchPayload(
          keyword: normalizedKw,
          page: page,
          sort: _sortType,
          categories: _selectedCategories,
        );
        try {
          final response = await searchComics(payload);
          SearchCache.put(cacheKey, page, response);
          return response;
        } catch (_) {
          return null;
        }
      }));

      if (!_autoFilling || !mounted) break;

      // 过滤并累积结果
      final existingDocs = _handler.state.data?.comics.docs ?? [];
      final allFiltered = List<SearchComic>.from(existingDocs);
      for (final result in results) {
        if (result == null) continue;
        final filtered = _applyBooleanFilter(
          result.comics.docs,
          _currentQuery,
        );
        allFiltered.addAll(filtered);
      }

      // 去重并更新 UI
      final seen = <String>{};
      final deduped = allFiltered.where((c) => seen.add(c.uid)).toList();
      _nextServerPage = (pagesToFetch[i + batch.length - 1]) + 1;
      final base = _handler.state.data;
      if (base != null) {
        _handler.mutate(
          base.copyWith.comics(
            docs: deduped,
            total: deduped.length,
            pages: totalPages,
          ),
        );
      }

      if (deduped.length >= 20) break;

      // 批次间等待 1 秒（速率限制）
      if (i + batchSize < pagesToFetch.length) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // 同步页码，使后续 loadMore 从正确位置继续
    _page = _nextServerPage - 1;
    _autoFilling = false;
  }

  Future<void> _onPageChange(int page) async {
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

  Widget _buildBody() {
    return _buildRealtimeBody();
  }

  /// 实时模式 body（有布尔运算符时强制走连续行为）
  Widget _buildRealtimeBody() {
    // 有布尔运算符时，无论 pagination 设置都显示加载更多
    final showPageSelector = pagination && !_hasBoolOps;
    return switch (_handler.state) {
      RequestState(:final data) when data != null => CommonTMIList(
        controller: showPageSelector ? null : scrollController,
        comics: context.filtered(data.comics.docs),
        emptyRefreshCallback: () => _performSearch(page: _page),
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
                final loading = _handler.state.loading;
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
  // 辅助
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
