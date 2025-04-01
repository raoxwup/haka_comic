import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/history_helper.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final HistoryHelper _helper = HistoryHelper();
  final ScrollController _scrollController = ScrollController();

  List<HistoryDoc> _comics = [];
  int _comicsCount = 0;
  int _page = 1;

  bool get hasMore => _comics.length < _comicsCount;

  @override
  void initState() {
    _getComics(_page);
    _getComicsCount();
    _helper.addListener(_update);

    _scrollController.addListener(_onScroll);

    super.initState();
  }

  @override
  void dispose() {
    _helper.removeListener(_update);

    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _update() {
    final comics = _helper.query(1);
    setState(() {
      _comics = comics;
    });
  }

  void _getComics(int page) {
    final comics = _helper.query(page);
    setState(() {
      _comics.addAll(comics);
    });
  }

  _getComicsCount() {
    final count = _helper.count();
    setState(() {
      _comicsCount = count;
    });
  }

  void _onScroll() {
    final position = _scrollController.position;
    // 添加保护条件，确保列表可滚动
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      if (hasMore) {
        _page = _page + 1;
        _getComics(_page);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
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
            return ListItem(doc: _comics[index]);
          },
          itemCount: _comics.length,
        ),
      ],
    );
  }
}
