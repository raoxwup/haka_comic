import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/mixin/blocked_words.dart';
import 'package:haka_comic/mixin/pagination_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/views/comics/sort_type_selector.dart';
import 'package:haka_comic/widgets/base_page.dart';

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
    with AutoRegisterHandlerMixin, PaginationHandlerMixin, BlockedWordsMixin {
  ComicSortType sortType = ComicSortType.dd;
  int page = 1;
  List<Doc> _comics = [];

  late final handler = fetchComics.useRequest(
    onSuccess: (data, _) {
      Log.info("Fetch comics success", data.toString());
      setState(() {
        if (!pagination) {
          _comics.addAll(data.comics.docs);
        } else {
          _comics = data.comics.docs;
        }
      });
    },
    onError: (e, _) {
      Log.error('Fetch comics failed', e);
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [handler];

  @override
  Future<void> loadMore() async {
    final pages = handler.data?.comics.pages ?? 1;
    if (page >= pages) return;
    await _onPageChange(page + 1);
  }

  @override
  void initState() {
    super.initState();

    handler.run(
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
    final int pages = handler.data?.comics.pages ?? 1;

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
          body:
              pagination
                  ? BasePage(
                    isLoading: handler.isLoading || !completed,
                    onRetry: handler.refresh,
                    error: handler.error,
                    child: CommonTMIList(
                      controller: scrollController,
                      comics: _comics,
                      blockedTags: blockedTags,
                      blockedWords: blockedWords,
                      pageSelectorBuilder: (context) {
                        return PageSelector(
                          pages: pages,
                          onPageChange: _onPageChange,
                          currentPage: page,
                        );
                      },
                    ),
                  )
                  : BasePage(
                    isLoading: false,
                    onRetry: handler.refresh,
                    error: handler.error,
                    child: CommonTMIList(
                      controller: scrollController,
                      comics: _comics,
                      blockedTags: blockedTags,
                      blockedWords: blockedWords,
                      footerBuilder: (context) {
                        final loading = handler.isLoading;
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

  void _onSortTypeChange(ComicSortType type) {
    if (type == sortType) return;
    setState(() {
      sortType = type;
      page = 1;
      _comics = [];
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
      builder:
          (context) => SortTypeSelector(
            sortType: sortType,
            onSortTypeChange: _onSortTypeChange,
          ),
    );
  }
}
