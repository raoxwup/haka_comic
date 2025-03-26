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
  List<HistoryDoc> _comics = [];
  int _comicsCount = 0;

  bool get hasMore => _comics.length < _comicsCount;

  @override
  void initState() {
    _getComics();
    _getComicsCount();
    HistoryHelper.instance.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    HistoryHelper.instance.removeListener(_update);
    super.dispose();
  }

  void _update() async {
    final comics = await HistoryHelper.instance.query();
    setState(() {
      _comics = comics;
    });
  }

  void _getComics({DateTime? lastUpdatedAt}) async {
    final comics = await HistoryHelper.instance.query(
      lastUpdatedAt: lastUpdatedAt,
    );
    setState(() {
      _comics.addAll(comics);
    });
  }

  void _getComicsCount() async {
    final count = await HistoryHelper.instance.count();
    setState(() {
      _comicsCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return CustomScrollView(
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
