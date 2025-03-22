import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
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

class _ComicsState extends State<Comics> {
  ComicSortType sortType = ComicSortType.dd;
  int page = 1;

  final handler = fetchComics.useRequest(
    onSuccess: (data, _) {
      Log.info("Fetch comics success", data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comics failed', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    handler
      ..addListener(_update)
      ..run(
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
    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  void _onPageChange(int page) {
    setState(() {
      this.page = page;
    });
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

  @override
  Widget build(BuildContext context) {
    final List<Doc> comics = handler.data?.comics.docs ?? [];
    final int pages = handler.data?.comics.pages ?? 1;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.c ?? widget.t ?? widget.a ?? widget.ct ?? widget.ca ?? '漫画',
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
        isLoading: handler.isLoading,
        onRetry: handler.refresh,
        error: handler.error,
        child: CustomScrollView(
          slivers: [
            PageSelector(
              pages: pages,
              onPageChange: _onPageChange,
              currentPage: page,
            ),
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent:
                    UiMode.m1(context)
                        ? width
                        : UiMode.m2(context)
                        ? width / 2
                        : width / 3,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                return ListItem(doc: comics[index]);
              },
              itemCount: comics.length,
            ),
            PageSelector(
              pages: pages,
              onPageChange: _onPageChange,
              currentPage: page,
            ),
          ],
        ),
      ),
    );
  }

  void _onSortTypeChange(ComicSortType type) {
    setState(() {
      sortType = type;
      page = 1;
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
