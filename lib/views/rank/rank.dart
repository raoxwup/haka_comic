import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Rank extends StatefulWidget {
  const Rank({super.key});

  @override
  State<Rank> createState() => _RankState();
}

class _RankState extends State<Rank> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('排行榜'),
          bottom: const TabBar(
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: [
              Tab(text: '日榜'),
              Tab(text: '周榜'),
              Tab(text: '月榜'),
              Tab(text: '骑士榜'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ComicRank(type: ComicRankType.H24),
            ComicRank(type: ComicRankType.D7),
            ComicRank(type: ComicRankType.D30),
            Center(child: Text('骑士榜')),
          ],
        ),
      ),
    );
  }
}

class ComicRank extends StatefulWidget {
  const ComicRank({super.key, required this.type});

  final ComicRankType type;

  @override
  State<ComicRank> createState() => _ComicRankState();
}

class _ComicRankState extends State<ComicRank>
    with AutomaticKeepAliveClientMixin {
  final _handler = fetchComicRank.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic rank success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic rank error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    _handler
      ..addListener(_update)
      ..run(ComicRankPayload(type: widget.type));
    super.initState();
  }

  @override
  void dispose() {
    _handler
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final comics = _handler.data?.comics ?? [];
    final width = context.width;

    return BasePage(
      isLoading: _handler.isLoading,
      onRetry: _handler.refresh,
      error: _handler.error,
      child: CustomScrollView(
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
              return ListItem(doc: comics[index]);
            },
            itemCount: comics.length,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
