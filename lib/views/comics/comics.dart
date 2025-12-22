import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/blocked_words.dart';
import 'package:haka_comic/mixin/pagination_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_pagination_footer.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_type_selector.dart';
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

class _ComicsState extends State<Comics>
    with RequestMixin, PaginationHandlerMixin, BlockedWordsMixin {
  ComicSortType sortType = ComicSortType.dd;
  int page = 1;
  List<Doc> _comics = [];

  late final handler = fetchComics.useRequest(
    defaultParams: ComicsPayload(
      c: widget.c,
      s: sortType,
      page: page,
      t: widget.t,
      ca: widget.ca,
      a: widget.a,
      ct: widget.ct,
    ),
    onSuccess: (data, _) {
      Log.info("Fetch comics success", data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comics failed', e);
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
  List<ComicBase> get comics => _comics;

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
    await handler.run(
      ComicsPayload(
        c: widget.c,
        s: sortType,
        page: page,
        t: widget.t,
        ca: widget.ca,
        a: widget.a,
        ct: widget.ct,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.c ??
                  widget.t ??
                  widget.a ??
                  widget.ct ??
                  widget.ca ??
                  '最近更新',
            ),
            actions: [
              IconButton(
                tooltip: '排序',
                icon: const Icon(Icons.sort),
                onPressed: _buildSortTypeSelector,
              ),
            ],
          ),
          body: switch (handler.state) {
            RequestState(:final data) when data != null => CommonTMIList(
              controller: pagination ? null : scrollController,
              comics: data.comics.docs,
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
      },
    );
  }

  void _onSortTypeChange(ComicSortType type) {
    if (type == sortType) return;
    setState(() {
      sortType = type;
      page = 1;
      _comics = [];
      filterComics();
    });
    handler.run(
      ComicsPayload(
        c: widget.c,
        s: type,
        page: 1,
        t: widget.t,
        ca: widget.ca,
        a: widget.a,
        ct: widget.ct,
      ),
    );
  }

  void _buildSortTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => SortTypeSelector(
        sortType: sortType,
        onSortTypeChange: _onSortTypeChange,
      ),
    );
  }
}
