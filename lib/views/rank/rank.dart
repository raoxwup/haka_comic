import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/ui_image.dart';

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
    with AutomaticKeepAliveClientMixin, RequestMixin {
  late final _handler = fetchComicRank.useRequest(
    defaultParams: ComicRankPayload(type: widget.type),
    onSuccess: (data, _) {
      Log.info('Fetch comic rank success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic rank error', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return switch (_handler.state) {
      Success(:final data) => CommonTMIList(
        comics: context.filtered(data.comics),
      ),
      Error(:final error) => ErrorPage(
        errorMessage: error.toString(),
        onRetry: _handler.refresh,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  @override
  bool get wantKeepAlive => true;
}

class KnightRank extends StatefulWidget {
  const KnightRank({super.key});

  @override
  State<KnightRank> createState() => _KnightRankState();
}

class _KnightRankState extends State<KnightRank> with RequestMixin {
  final _handler = fetchKnightRank.useRequest(
    onSuccess: (data) {
      Log.info('Fetch knight rank success', data.toString());
    },
    onError: (e) {
      Log.error('Fetch knight rank error', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    return switch (_handler.state) {
      Success(:final data) => ListView.separated(
        itemBuilder: (context, index) {
          final user = data.users[index];
          return InkWell(
            onTap: () => context.push('/comics?ca=${user.id}'),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiImage(
                    url: user.avatar?.url ?? '',
                    width: 48,
                    height: 48,
                    shape: .circle,
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
        itemCount: data.users.length,
      ),
      Error(:final error) => ErrorPage(
        errorMessage: error.toString(),
        onRetry: _handler.refresh,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
