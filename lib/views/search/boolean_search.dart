import 'dart:async';

import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/boolean_parser.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/search_filter.dart';
import 'package:haka_comic/views/search/search_cache.dart';
import 'package:haka_comic/views/search/search_probe.dart';

/// 布尔搜索引擎：封装所有布尔搜索的状态和逻辑
///
/// 管理关键词探测、缓存读写、worker pool 并发、失败重试、关键词切换等。
/// widget 只需调用 [searchFirstPage] / [searchNextPage] / [loadMore]，
/// 通过 [onResults] 回调接收累积的过滤结果。
class BooleanSearchEngine {
  BooleanSearchEngine({
    required this.query,
    required this.sortType,
    required this.categories,
    required this.normalizeKeyword,
    required this.onResults,
  });

  final SearchQuery query;
  final ComicSortType sortType;
  final List<String> categories;
  final String Function(String) normalizeKeyword;

  /// 结果更新回调（UI 层通过此回调 mutate handler）
  ///
  /// 参数: [results] 当前所有已过滤且去重的漫画列表
  /// 可在构造后重新赋值（解决 Dart 局部变量自引用限制）
  void Function(List<SearchComic> results) onResults;

  // ── 状态 ──────────────────────────────────────────────

  List<SearchComic> _allFiltered = [];
  final Set<String> _globalSeen = {};
  SearchResponse? _baseResponse;

  int _nextServerPage = 1;
  bool _autoFilling = false;
  int _serverTotal = 0;

  // ── 失败页收集 ────────────────────────────────────────

  final _failedPages = <int, int>{};
  static const _maxFailRetries = 2;
  bool _switched = false; // 防止级联切换

  // ── 关键词探测 ────────────────────────────────────────

  String? _optimalServerKeyword;

  // ── 缓存 key（自动同步）───────────────────────────────

  String _searchCacheKey = '';
  String _serverKeyword = '';

  // ── 公开 API ──────────────────────────────────────────

  List<SearchComic> get results => _allFiltered;
  bool get isAutoFilling => _autoFilling;
  int get serverTotal => _serverTotal;
  int get nextServerPage => _nextServerPage;

  /// 生成包含当前过滤结果的 SearchResponse
  SearchResponse? responseWithResults() {
    final base = _baseResponse;
    if (base == null) return null;
    return base.copyWith.comics(
      docs: List.of(_allFiltered),
      total: _allFiltered.length,
    );
  }

  /// 首页搜索：关键词探测 + 缓存读取 + API 请求 + 启动 autoFill
  ///
  /// 返回 [SearchResponse] 表示 widget 应用此结果更新 UI；
  /// 返回 null 表示结果已过期、被取消或无数据。
  Future<SearchResponse?> searchFirstPage() async {
    _allFiltered = [];
    _globalSeen.clear();
    _optimalServerKeyword = null;
    _failedPages.clear();
    _nextServerPage = 1;
    _switched = false;

    // ── 关键词探测 ─────────
    final normalizedKeyword = await _probeIfNeeded();
    if (normalizedKeyword == null) {
      Log.w('Bool search probe cancelled', '');
      return null;
    }

    _ensureCacheKey(normalizedKeyword);

    // ── 获取首页数据 ─────────
    final cacheKey = _searchCacheKey;
    final probeResult = _probeResult;

    if (SearchCache.contains(cacheKey)) {
      final cached = SearchCache.get(cacheKey, 1);
      if (cached != null) {
        final filtered = _filter(cached.comics.docs);
        // 必须将过滤结果存入 _allFiltered 并更新 _baseResponse
        // 否则 _runAutoFill 会用未过滤数据重置 _allFiltered
        _allFiltered = List.of(filtered);
        _globalSeen.addAll(_allFiltered.map((c) => c.uid));
        _baseResponse = cached.copyWith.comics(
          docs: List.of(_allFiltered),
          total: _allFiltered.length,
        );
        _serverTotal = cached.comics.total;
        if (filtered.isNotEmpty) {
          _emitResults();
          _tryAutoFill(cached.comics.pages);
          return responseWithResults();
        }
        // 页 1 过滤为 0，但后续页可能有匹配 → 返回空响应 + 启动 autoFill
        // UI 检测 isAutoFilling 显示加载态而非"没有数据"
        _tryAutoFill(cached.comics.pages);
        return responseWithResults();
      }
    }

    // ── 无缓存 → 使用 probeResult 或发请求 ─────────
    SearchResponse? fresh;
    if (probeResult != null) {
      fresh = probeResult;
      SearchCache.put(cacheKey, 1, fresh);
    } else {
      fresh = await _fetchRaw(1);
      if (fresh == null) return null;
    }

    _serverTotal = fresh.comics.total;
    _baseResponse = fresh;
    SearchProbeCache.put(normalizedKeyword, categories, fresh.comics.total);

    // 缓存新鲜度校验
    if (SearchCache.getCachedPages(cacheKey).isNotEmpty) {
      if (SearchCache.validateFreshness(cacheKey, fresh)) {
        SearchCache.touch(cacheKey);
      } else {
        SearchCache.remove(cacheKey);
        SearchCache.put(cacheKey, 1, fresh);
      }
    } else {
      SearchCache.put(cacheKey, 1, fresh);
    }

    final filtered = _filter(fresh.comics.docs);
    _allFiltered = List.of(filtered);
    _globalSeen.addAll(_allFiltered.map((c) => c.uid));
    _baseResponse = fresh.copyWith.comics(
      docs: List.of(_allFiltered),
      total: _allFiltered.length,
    );
    if (filtered.isNotEmpty) {
      _emitResults();
      _tryAutoFill(fresh.comics.pages);
      return responseWithResults();
    }

    // 0 匹配但仍启动 autoFill（后续页可能有匹配）
    // 返回空响应，UI 检测 isAutoFilling 显示加载态
    _tryAutoFill(fresh.comics.pages);
    return responseWithResults();
  }

  /// 后续页搜索（page 2+）
  ///
  /// 返回 null 表示结果已过期或无数据。
  Future<SearchResponse?> searchNextPage(int page) async {
    final normalizedKeyword = _optimalServerKeyword ??
        normalizeKeyword(query.firstServerKeyword ?? '');
    if (normalizedKeyword.isEmpty) return null;

    _ensureCacheKey(normalizedKeyword);

    final cacheKey = _searchCacheKey;
    if (SearchCache.contains(cacheKey)) {
      final cached = SearchCache.get(cacheKey, page);
      if (cached != null) {
        final filtered = _filter(cached.comics.docs);
        if (filtered.isNotEmpty) {
          for (final c in filtered) {
            if (_globalSeen.add(c.uid)) _allFiltered.add(c);
          }
          _baseResponse ??= cached.copyWith.comics(
            docs: List.of(_allFiltered),
            total: _allFiltered.length,
          );
          _serverTotal = cached.comics.total;
          _emitResults();
          _tryAutoFill(cached.comics.pages);
          return responseWithResults();
        }
        return null;
      }
    }

    final fresh = await _fetchRaw(page);
    if (fresh == null) return null;

    _serverTotal = fresh.comics.total;
    SearchCache.put(cacheKey, page, fresh);
    SearchProbeCache.put(normalizedKeyword, categories, fresh.comics.total);

    final filtered = _filter(fresh.comics.docs);
    for (final c in filtered) {
      if (_globalSeen.add(c.uid)) _allFiltered.add(c);
    }
    _baseResponse ??= fresh.copyWith.comics(
      docs: List.of(_allFiltered),
      total: _allFiltered.length,
    );
    if (filtered.isNotEmpty) {
      _emitResults();
    }

    _tryAutoFill(fresh.comics.pages);
    return responseWithResults();
  }

  /// 自动填充：并发扫描剩余所有页面
  Future<void> autoFill(int totalPages) async {
    await _runAutoFill(totalPages, isRetry: false);
  }

  /// loadMore：重试失败页 + 拉取新页
  Future<void> loadMore(int totalPages) async {
    if (_autoFilling) return;
    final retryPages = _failedPages.entries
        .where((e) => e.value < _maxFailRetries)
        .map((e) => e.key)
        .toList();
    final newPages = [
      for (int p = _nextServerPage; p <= totalPages; p++) p,
    ];
    final allPages = {...retryPages, ...newPages}.toList()..sort();
    if (allPages.isEmpty) return;

    _autoFilling = true;
    _allFiltered = List.of(_baseResponse?.comics.docs ?? []);
    _globalSeen
      ..clear()
      ..addAll(_allFiltered.map((c) => c.uid));

    try {
      await _runWorkers(allPages, retry: true, collectFailures: true);
      _emitResults();
    } finally {
      _autoFilling = false;
    }
  }

  // ── 内部方法 ──────────────────────────────────────────

  SearchResponse? _probeResult;

  /// 关键词探测：选择 total 最小的候选词
  ///
  /// 返回最优关键词，null 表示被取消
  Future<String?> _probeIfNeeded() async {
    _probeResult = null;
    if (!query.hasBoolOps) {
      return normalizeKeyword(query.firstServerKeyword ?? '');
    }

    final candidates = query.candidateKeywords;
    if (candidates.isEmpty) {
      return normalizeKeyword(query.firstServerKeyword ?? '');
    }

    Log.d('Bool search probe calling', '');
    final (kw, resp) = await probeOptimalKeyword(
      candidates: candidates,
      sortType: sortType,
      categories: categories,
      normalizeKeyword: normalizeKeyword,
      onSlowerCandidate: (optKw, optTotal, optResp) {
        _onProbeCandidate(optKw, optTotal, optResp);
      },
    );
    Log.i('Bool search probe returned', 'kw=$kw hasResp=${resp != null}');

    _optimalServerKeyword = kw;
    _probeResult = resp;
    return kw;
  }

  /// 确保缓存 key 已计算（仅在关键词确定后调用一次）
  void _ensureCacheKey(String normalizedKeyword) {
    _serverKeyword = normalizedKeyword;
    _searchCacheKey = SearchCache.buildKey(
      normalizedKeyword, sortType, categories,
    );
  }

  /// 如果有多页结果且尚未启动 autoFill，启动后台扫描
  void _tryAutoFill(int totalPages) {
    if (totalPages > 1 && !_autoFilling) {
      _nextServerPage = 2;
      Log.i('Bool search autoFill starting', '$totalPages pages');
      unawaited(_runAutoFill(totalPages, isRetry: false));
    }
  }

  /// 内部 autoFill 实现
  Future<void> _runAutoFill(int totalPages, {required bool isRetry}) async {
    _autoFilling = true;

    _ensureCacheKey(_serverKeyword);
    _allFiltered = List.of(_baseResponse?.comics.docs ?? []);
    _globalSeen
      ..clear()
      ..addAll(_allFiltered.map((c) => c.uid));

    try {
      final pages = List.generate(
        totalPages - _nextServerPage + 1,
        (i) => _nextServerPage + i,
      );
      Log.i('Bool search autoFill running',
          'remaining=${pages.length} pages');
      await _runWorkers(pages, retry: true, collectFailures: true);

      Log.i('Bool search autoFill completed',
          '${_allFiltered.length} results');
      _emitResults();
    } finally {
      _autoFilling = false;
    }
  }

  /// 获取单页原始数据（无过滤、无缓存管理，仅网络请求 + 写缓存）
  Future<SearchResponse?> _fetchRaw(int page) async {
    final payload = SearchPayload(
      keyword: _serverKeyword,
      page: page,
      sort: sortType,
      categories: categories,
    );
    try {
      return await searchComics(payload);
    } catch (e) {
      Log.e('Bool search fetch failed', error: e);
      return null;
    }
  }

  /// Worker pool：多 worker 并发消费页码列表
  Future<void> _runWorkers(
    List<int> pages, {
    required bool retry,
    required bool collectFailures,
  }) async {
    int next = 0;
    int workerId = 0;
    Future<void> worker() async {
      final id = workerId++;
      while (_autoFilling) {
        if (next >= pages.length) return;
        final p = pages[next++];
        final result = await _fetchPage(p, retry: retry);
        _mergeResult(result, collectFailures: collectFailures);
      }
    }

    final count = pages.length.clamp(1, AppConf().maxRequestsPerSecond);
    await Future.wait(List.generate(count, (_) => worker()));
  }

  /// 单页请求：优先读缓存，缓存未命中则发网络请求
  Future<(int, SearchResponse?)> _fetchPage(int p, {bool retry = false}) async {
    if (!_autoFilling) return (p, null);
    final myCacheKey = _searchCacheKey;
    final myKeyword = _serverKeyword;
    final cached = SearchCache.get(myCacheKey, p);
    if (cached != null) return (p, cached);

    final payload = SearchPayload(
      keyword: myKeyword,
      page: p,
      sort: sortType,
      categories: categories,
    );
    for (int attempt = 0; attempt < (retry ? 2 : 1); attempt++) {
      await searchLimiter.wait();
      if (!_autoFilling) return (p, null);
      try {
        final resp = await searchComics(payload);
        SearchCache.put(myCacheKey, p, resp);
        return (p, resp);
      } catch (e) {
        Log.e('FetchPage failed', error: e);
        if (attempt == 0 && retry) continue;
        return (p, null);
      }
    }
    return (p, null);
  }

  /// 将单页结果合并到 [_allFiltered]
  void _mergeResult(
    (int, SearchResponse?) item, {
    bool collectFailures = false,
  }) {
    final (p, result) = item;
    if (result == null) {
      Log.i('Bool search page failed', 'page=$p');
      if (collectFailures) {
        final count = (_failedPages[p] ?? 0) + 1;
        if (count < _maxFailRetries) {
          _failedPages[p] = count;
        } else {
          _failedPages.remove(p);
        }
      }
      return;
    }
    _failedPages.remove(p);
    final beforeCount = _allFiltered.length;
    for (final c in _filter(result.comics.docs)) {
      if (_globalSeen.add(c.uid)) {
        _allFiltered.add(c);
      }
    }
    if (_allFiltered.length > beforeCount) {
      _baseResponse ??= result;
      onResults(_allFiltered);
    }
    // 推进 _nextServerPage
    if (p == _nextServerPage) {
      _nextServerPage++;
      while (SearchCache.get(_searchCacheKey, _nextServerPage) != null) {
        _nextServerPage++;
      }
    }
  }

  /// 布尔过滤
  List<SearchComic> _filter(List<SearchComic> docs) {
    return applyBooleanFilter(docs, query);
  }

  /// 通知 UI 更新
  void _emitResults() {
    onResults(_allFiltered);
  }

  // ═══════════════════════════════════════
  // 关键词切换
  // ═══════════════════════════════════════

  /// probe 后续候选词到达时的回调
  ///
  /// 判断逻辑：已拉取条目 = (nextServerPage - 1) * 20
  ///          剩余 ≈ serverTotal - 已拉取
  ///          candidateTotal < 剩余 → 候选词更优，值得切换
  void _onProbeCandidate(String kw, int total, SearchResponse? resp) {
    if (!_autoFilling || _switched) return;

    final fetchedItems = (_nextServerPage - 1) * 20;
    final remaining = _serverTotal - fetchedItems;

    Log.i('Bool search probe candidate',
        '$kw total=$total, serverTotal=$_serverTotal, '
        'remaining≈$remaining');

    if (total < remaining) {
      Log.i('Bool search switching keyword', kw);
      _switched = true;
      _switchToKeyword(kw, resp);
    }
  }

  /// 切换到更优关键词：停止当前 autoFill → 更新关键词 → 重启 autoFill
  void _switchToKeyword(String kw, SearchResponse? resp) {
    _autoFilling = false;

    _optimalServerKeyword = kw;
    _ensureCacheKey(kw);

    if (resp == null) {
      Log.w('Bool search switch aborted', 'resp is null for $kw');
      return;
    }

    SearchCache.put(_searchCacheKey, 1, resp);

    final newMatches = _filter(resp.comics.docs);
    for (final c in newMatches) {
      if (_globalSeen.add(c.uid)) {
        _allFiltered.add(c);
      }
    }
    // 必须在 _runAutoFill 之前更新 _baseResponse
    // 因为 _runAutoFill 会从 _baseResponse 重置 _allFiltered
    _baseResponse = resp.copyWith.comics(
      docs: List.of(_allFiltered),
      total: _allFiltered.length,
    );
    _serverTotal = resp.comics.total;

    Log.i('Bool search keyword switched',
        'pages=${resp.comics.pages}, matches=${_allFiltered.length}');
    onResults(_allFiltered);

    if (resp.comics.pages > 1) {
      _nextServerPage = 1;
      unawaited(_runAutoFill(resp.comics.pages, isRetry: false));
    }
  }

  /// 是否有布尔运算符（AND / NOT）
  bool get hasBoolOps => query.hasBoolOps;
}

extension on SearchQuery {
  bool get hasBoolOps => andWords.isNotEmpty || notWords.isNotEmpty;
}
