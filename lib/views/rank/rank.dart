import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Rank extends StatefulWidget {
  const Rank({super.key});

  @override
  State<Rank> createState() => _RankState();
}

class _RankState extends State<Rank> {
  @override
  Widget build(BuildContext context) {
    return RouteAwarePageWrapper(
      builder: (context, completed) {
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
            body: TabBarView(
              children: [
                ComicRank(
                  type: ComicRankType.H24,
                  isRouteAnimationCompleted: completed,
                ),
                ComicRank(
                  type: ComicRankType.D7,
                  isRouteAnimationCompleted: completed,
                ),
                ComicRank(
                  type: ComicRankType.D30,
                  isRouteAnimationCompleted: completed,
                ),
                const KnightRank(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ComicRank extends StatefulWidget {
  const ComicRank({
    super.key,
    required this.type,
    required this.isRouteAnimationCompleted,
  });

  final ComicRankType type;

  final bool isRouteAnimationCompleted;

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
      isLoading: _handler.isLoading || !widget.isRouteAnimationCompleted,
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

class KnightRank extends StatefulWidget {
  const KnightRank({super.key});

  @override
  State<KnightRank> createState() => _KnightRankState();
}

class _KnightRankState extends State<KnightRank> {
  final _handler = fetchKnightRank.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch knight rank success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch knight rank error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    super.initState();
    _handler
      ..addListener(_update)
      ..run();
  }

  @override
  void dispose() {
    super.dispose();
    _handler
      ..removeListener(_update)
      ..dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = _handler.data?.users ?? [];

    return BasePage(
      isLoading: _handler.isLoading,
      onRetry: _handler.refresh,
      error: _handler.error,
      child: ListView.separated(
        itemBuilder: (context, index) {
          final user = users[index];
          return InkWell(
            onTap: () => context.push('/comics?ca=${user.id}'),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BaseImage(
                    url: user.avatar?.url ?? '',
                    width: 48,
                    height: 48,
                    shape: const CircleBorder(),
                  ),
                  Expanded(
                    child: Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: context.textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${user.comicsUploaded}本',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Lv.${user.level} (${user.title})',
                          style: context.textTheme.labelMedium,
                        ),
                        Text(user.slogan, style: context.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemCount: users.length,
      ),
    );
  }
}
