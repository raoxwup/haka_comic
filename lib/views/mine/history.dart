import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/history_helper.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/views/comics/page_selector.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Doc> _comics = [];
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    setState(() {
      _comics = HistoryHelper.instance.query(1);
      _pages = HistoryHelper.instance.count();
    });
    super.initState();
  }

  void _onPageChange(int page) => setState(() {
    _comics = HistoryHelper.instance.query(page);
    _page = page;
  });

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return CustomScrollView(
      slivers: [
        PageSelector(
          pages: _pages,
          onPageChange: _onPageChange,
          currentPage: _page,
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
            return ListItem(doc: _comics[index]);
          },
          itemCount: _comics.length,
        ),
        PageSelector(
          pages: _pages,
          onPageChange: _onPageChange,
          currentPage: _page,
        ),
      ],
    );
  }
}
