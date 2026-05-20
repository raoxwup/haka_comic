import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_and_filter_toolbar.dart';
import 'package:haka_comic/widgets/error_page.dart';

class Comics extends StatefulWidget {
  const Comics({super.key, this.t, this.c, this.a, this.ct, this.ca});

  // Tag
  final String? t;

  // 分类
  final String? c;

  // 作者
  final String? a;

  // 汉化组
  final String? ct;

  // 上传者
  final String? ca;

  @override
  State<Comics> createState() => _ComicsState();
}

class _ComicsState extends State<Comics> with RequestMixin, PaginationMixin {
  ComicSortType sortType = ComicSortType.dd;
  List<String> _selectedCategories = [];
  int page = 1;

  /// 路由参数中的分类列表
  List<String> get _routeCategories =>
      widget.c?.split(',').where((s) => s.isNotEmpty).toList() ?? [];

  /// 合并路由参数中的分类和用户手动选择的分类（去重）
  String? get _effectiveCategory {
    final all = {..._routeCategories, ..._selectedCategories};
    if (all.isEmpty) return null;
    return all.join(',');
  }

  ComicsPayload _buildPayload({int? page}) => ComicsPayload(
    c: _effectiveCategory,
    s: sortType,
    page: page ?? this.page,
    t: widget.t,
    ca: widget.ca,
    a: widget.a,
    ct: widget.ct,
  );

  late final handler = fetchComics.useRequest(
    defaultParams: _buildPayload(),
    onSuccess: (data, _) {
      Log.i("Fetch comics success", data.toString());
    },
    onError: (e, _) {
      Log.e('Fetch comics failed', error: e);
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

  @override
  List<RequestHandler> registerHandler() => [handler];

  @override
  Future<void> loadMore() async {
    final pages = handler.state.data?.comics.pages ?? 1;
    if (page >= pages) return;
    await _onPageChange(page + 1);
  }

  Future<void> _onPageChange(int page) async {
    setState(() {
      this.page = page;
    });
    await handler.run(_buildPayload(page: page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.c ?? widget.t ?? widget.a ?? widget.ct ?? widget.ca ?? '最近更新',
        ),
        actions: [
          ...SortAndFilterToolbar(
            sortType: sortType,
            selectedCategories: _selectedCategories,
            onSortTypeChange: _onSortTypeChange,
            onCategoriesChange: _onCategoriesChange,
            routeCategories: _routeCategories,
          ).buildButtons(context),
        ],
      ),
      body: switch (handler.state) {
        RequestState(:final data) when data != null => CommonTMIList(
          controller: pagination ? null : scrollController,
          comics: context.filtered(data.comics.docs),
          emptyRefreshCallback: () {
            handler.resetState();
            handler.run(_buildPayload(page: 1));
          },
          pageSelectorBuilder: pagination
              ? (context) {
                  return PageSelector(
                    pages: data.comics.pages,
                    onPageChange: _onPageChange,
                    currentPage: page,
                  );
                }
              : null,
          footerBuilder: pagination
              ? null
              : (context) {
                  final loading = handler.state.loading;
                  return CommonPaginationFooter(loading: loading);
                },
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: handler.refresh,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  void _onSortTypeChange(ComicSortType type) {
    if (type == sortType) return;
    setState(() {
      sortType = type;
      page = 1;
    });
    handler.resetState();
    handler.run(_buildPayload(page: 1));
  }

  void _onCategoriesChange(List<String> categories) {
    setState(() {
      _selectedCategories = categories;
      page = 1;
    });
    handler.resetState();
    handler.run(_buildPayload(page: 1));
  }
}
