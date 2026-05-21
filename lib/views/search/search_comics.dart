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
import 'package:haka_comic/utils/search_filter.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_and_filter_toolbar.dart';
import 'package:haka_comic/views/search/search_cache.dart';
import 'package:haka_comic/views/search/search_probe.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:pinyin/pinyin.dart';
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

  // ── 关键词探测 ─────────────────────────────
  bool _probedKeywords = false;
  String? _optimalServerKeyword;

  // ── 快速翻页预加载 ───────────────────────────
  final List<DateTime> _recentPageChangeTimes = [];
  static const _prefetchRapidCount = 3;
  static const _prefetchInterval = Duration(seconds: 2);

  bool get _hasBoolOps =>
      AppConf().enableBooleanSearch &&
      (_currentQuery.andWords.isNotEmpty || _currentQuery.notWords.isNotEmpty);

  /// 客户端布尔过滤：按 orWords/andWords/notWords 过滤 API 返回结果
  List<SearchComic> _applyBooleanFilter(
    List<SearchComic> docs,
    SearchQuery query,
  ) => applyBooleanFilter(docs, query);

  /// 根据设置规范化搜索词（简繁转换）
  String _normalizeKeyword(String keyword) {
    final mode = AppConf().searchNormalization;
    if (mode == 'off') return keyword;
    if (mode == 's2t') return ChineseHelper.convertToTraditionalChinese(keyword);
    return ChineseHelper.convertToSimplifiedChinese(keyword);
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
    _searchController.dispose();
    super.dispose();
  }

  /// 统一搜索入口
  /// [silent] 为 true 时仅写入缓存，不更新 UI（用于预加载）
  Future<void> _performSearch({int? page, bool silent = false}) async {
    final targetPage = page ?? 1;
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // 新搜索取消前一次自动填充
    if (!silent) _autoFilling = false;

    _currentQuery = AppConf().enableBooleanSearch
        ? parseSearchQuery(keyword)
        : const SearchQuery();

    // 新搜索重置探测状态（翻页不重置）
    if (targetPage == 1) {
      _probedKeywords = false;
      _optimalServerKeyword = null;
    }

    // 统一行为：清空旧数据（显示全屏加载动画，禁止点击）+ 重置滚动条
    if (!silent) {
      _handler.resetState();
      _page = targetPage;
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }
    await _performRealtimeSearch(targetPage, silent: silent);
  }

  // ═══════════════════════════════════════
  // 搜索请求
  // ═══════════════════════════════════════

  Future<void> _performRealtimeSearch(int page, {bool silent = false}) async {
    // ── 关键词选择（探测最优 or 直接用） ─────────
    String normalizedKeyword;
    SearchResponse? probeResult;

    if (_hasBoolOps && !_probedKeywords) {
      // 布尔模式首次搜索：探测最优关键词
      final candidates = _currentQuery.candidateKeywords;
      if (candidates.isEmpty) {
        normalizedKeyword = _normalizeKeyword(_searchController.text);
      } else {
        final (kw, resp) = await probeOptimalKeyword(
          candidates: candidates,
          sortType: _sortType,
          categories: _selectedCategories,
          normalizeKeyword: _normalizeKeyword,
        );
        normalizedKeyword = kw;
        probeResult = resp;
        _probedKeywords = true;
        _optimalServerKeyword = kw;
      }
    } else if (_hasBoolOps && _optimalServerKeyword != null) {
      // 布尔模式后续翻页：复用已探测的最优词
      normalizedKeyword = _optimalServerKeyword!;
    } else {
      // 非布尔模式
      normalizedKeyword = _normalizeKeyword(_searchController.text);
    }

    final cacheKey = SearchCache.buildKey(
      normalizedKeyword,
      _sortType,
      _selectedCategories,
    );

    if (SearchCache.contains(cacheKey)) {
      // 缓存条目存在（生命值 > 0）
      final cached = SearchCache.get(cacheKey, page);
      if (cached != null) {
        // 快速路径：指定页命中，生命值管理
        if (!silent) _handler.mutate(cached);
        SearchCache.touch(cacheKey);
        return;
      }
      // 缓存存在但没这一页 → 发请求，补充该页
      final payload = SearchPayload(
        keyword: normalizedKeyword,
        page: page,
        sort: _sortType,
        categories: _selectedCategories,
      );
      await _handler.run(payload);
      if (_handler.state.hasData) {
        SearchCache.put(cacheKey, page, _handler.state.data!);
        SearchCache.touch(cacheKey);
        SearchProbeCache.put(
          normalizedKeyword,
          _selectedCategories,
          _handler.state.data!.comics.total,
        );
        if (!silent) _handler.mutate(_handler.state.data!);
      }
    } else {
      // 无缓存 → 新建条目
      // probe 可能已写入 SearchCache，先检查
      final cached = SearchCache.get(cacheKey, page);
      SearchResponse? fresh;

      if (cached != null) {
        fresh = cached; // probe 写入的 page 1
      } else if (probeResult != null && page == 1) {
        fresh = probeResult; // probe 直接返回的结果
      } else {
        final payload = SearchPayload(
          keyword: normalizedKeyword,
          page: page,
          sort: _sortType,
          categories: _selectedCategories,
        );
        await _handler.run(payload);
        fresh = _handler.state.data;
        if (fresh != null) {
          SearchProbeCache.put(
            normalizedKeyword,
            _selectedCategories,
            fresh.comics.total,
          );
        }
      }

      if (fresh != null) {
        if (page == 1 && SearchCache.getCachedPages(cacheKey).isNotEmpty) {
          // 条目已过期但仍有缓存数据 → 做新鲜度校验
          if (SearchCache.validateFreshness(cacheKey, fresh)) {
            // 数据没变，续命并复用所有已缓存页
            SearchCache.touch(cacheKey);
            final pages = SearchCache.getCachedPages(cacheKey);
            if (pages.length > 1) {
              pages.sort();
              final farthest = SearchCache.get(cacheKey, pages.last);
              if (farthest != null && !silent) _handler.mutate(farthest);
            }
          } else {
            // 数据已变，清除旧缓存，重新缓存
            SearchCache.remove(cacheKey);
            SearchCache.put(cacheKey, 1, fresh);
          }
        } else {
          // 全新条目或非首页 → 直接缓存
          SearchCache.put(cacheKey, page, fresh);
        }
        if (!silent) _handler.mutate(fresh);
      }
    }

    // 有布尔运算符时，用过滤后的结果替换 handler 中的数据
    if (_hasBoolOps && _handler.state.hasData && !silent) {
      final raw = _handler.state.data!;
      final filtered = _applyBooleanFilter(raw.comics.docs, _currentQuery);
      _handler.mutate(
        raw.copyWith.comics(docs: filtered, total: filtered.length),
      );
    }

    // 有布尔运算符且过滤后不足 20 条，启动自动填充
    if (_hasBoolOps && page == 1 && !silent) {
      final currentCount = _handler.state.data?.comics.docs.length ?? 0;
      final totalPages = _handler.state.data?.comics.pages ?? 0;
      if (currentCount < 20 && totalPages > 1) {
        _nextServerPage = 2;
        _autoFillResults(totalPages);
      }
    }
  }

  /// 自动填充：布尔过滤后结果不足时，顺序请求后续页补充
  Future<void> _autoFillResults(int totalPages) async {
    _autoFilling = true;

    final serverKw = _optimalServerKeyword ??
        _normalizeKeyword(
          _currentQuery.firstServerKeyword ?? _searchController.text,
        );
    final cacheKey = SearchCache.buildKey(
      serverKw, _sortType, _selectedCategories,
    );
    final existingDocs = _handler.state.data?.comics.docs ?? [];
    final allFiltered = List<SearchComic>.from(existingDocs);
    final globalSeen = <String>{
      ...allFiltered.map((c) => c.uid),
    };

    for (int p = _nextServerPage;
        p <= totalPages && allFiltered.length < 20;
        p++) {
      if (!_autoFilling || !mounted) break;

      final cached = SearchCache.get(cacheKey, p);
      SearchResponse? result;
      if (cached != null) {
        result = cached;
      } else {
        await searchLimiter.wait();
        if (!_autoFilling || !mounted) break;
        final payload = SearchPayload(
          keyword: serverKw,
          page: p,
          sort: _sortType,
          categories: _selectedCategories,
        );
        try {
          result = await searchComics(payload);
          SearchCache.put(cacheKey, p, result);
        } catch (_) {
          break; // 某页失败则停止
        }
      }
      final filtered = _applyBooleanFilter(
        result.comics.docs,
        _currentQuery,
      );
      for (final c in filtered) {
        if (globalSeen.add(c.uid)) allFiltered.add(c);
      }
      _nextServerPage = p + 1;
    }

    if (!_autoFilling || !mounted) {
      _autoFilling = false;
      return;
    }
    _autoFilling = false;
    final base = _handler.state.data;
    if (base != null) {
      _handler.mutate(
        base.copyWith.comics(
          docs: allFiltered,
          total: allFiltered.length,
          pages: totalPages,
        ),
      );
    }
    // 同步页码，使后续 loadMore 从正确位置继续
    _page = _nextServerPage - 1;
  }

  Future<void> _onPageChange(int page) async {
    await _performSearch(page: page);
    _maybePrefetchNextPage();
  }

  /// 检测快速翻页行为，提前加载下一页到缓存
  void _maybePrefetchNextPage() {
    final now = DateTime.now();

    // 只保留最近的翻页记录
    _recentPageChangeTimes.add(now);
    if (_recentPageChangeTimes.length > _prefetchRapidCount) {
      _recentPageChangeTimes.removeAt(0);
    }

    // 收集足够的记录后检测：所有相邻间隔 < 2 秒即视为快速翻页
    if (_recentPageChangeTimes.length >= _prefetchRapidCount) {
      final span = now.difference(_recentPageChangeTimes.first);
      if (span < _prefetchInterval * _prefetchRapidCount) {
        final pages = _handler.state.data?.comics.pages ?? 0;
        final nextPage = _hasBoolOps ? _nextServerPage : _page + 1;
        if (nextPage <= pages) {
          // 与 _performRealtimeSearch 保持一致的 keyword 选择逻辑
          if (_hasBoolOps && _optimalServerKeyword != null) {
            // 布尔模式：用探测到的最优词预加载
            final ck = SearchCache.buildKey(
              _optimalServerKeyword!,
              _sortType,
              _selectedCategories,
            );
            if (SearchCache.get(ck, nextPage) == null) {
              unawaited(_performSearch(page: nextPage, silent: true));
            }
          } else {
            final serverKw = _searchController.text;
            final cacheKey = SearchCache.buildKey(
              _normalizeKeyword(serverKw),
              _sortType,
              _selectedCategories,
            );
            if (SearchCache.get(cacheKey, nextPage) == null) {
              unawaited(_performSearch(page: nextPage, silent: true));
            }
          }
        }
      }
    }
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
    // 翻页加载动画：请求进行中时全屏转圈（与原始 BasePage 行为一致）
    if (_handler.state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
