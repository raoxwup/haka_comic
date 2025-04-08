import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Mine extends StatefulWidget {
  const Mine({super.key});

  @override
  State<Mine> createState() => _MineState();
}

class _MineState extends State<Mine> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(bottom: 15),
      children: [
        const ProFile(),
        const Favorites(),
        const HistoryComics(),
        Card.outlined(
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => context.push('/downloads'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                spacing: 5,
                children: [
                  const Icon(Icons.download),
                  Text('我的下载', style: context.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        Card.outlined(
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => context.push('/comments'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                spacing: 5,
                children: [
                  const Icon(Icons.comment),
                  Text('我的评论', style: context.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProFile extends StatefulWidget {
  const ProFile({super.key});

  @override
  State<ProFile> createState() => _ProFileState();
}

class _ProFileState extends State<ProFile> {
  final _profileHandler = fetchUserProfile.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch user profile success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch user profile error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    _profileHandler
      ..addListener(_update)
      ..run();
    super.initState();
  }

  @override
  void dispose() {
    _profileHandler
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileHandler.data?.user;
    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 84),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: BasePage(
            isLoading: _profileHandler.isLoading,
            error: _profileHandler.error,
            onRetry: _profileHandler.refresh,
            child: Row(
              spacing: 15,
              children: [
                BaseImage(
                  url: user?.avatar.url ?? '',
                  width: 64,
                  height: 64,
                  shape: const CircleBorder(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: context.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Lv.${user?.level}  Exp: ${user?.exp}',
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.slogan ?? '',
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryComics extends StatefulWidget {
  const HistoryComics({super.key});

  @override
  State<HistoryComics> createState() => _HistoryComicsState();
}

class _HistoryComicsState extends State<HistoryComics> {
  final HistoryHelper _helper = HistoryHelper();
  List<HistoryDoc> _comics = [];

  void _getHistory() {
    final comics = _helper.query(1);
    setState(() {
      _comics = comics;
    });
  }

  @override
  void initState() {
    _getHistory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.push('/history'),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Row(
                spacing: 10,
                children: [
                  const Icon(Icons.history),
                  Text('浏览历史', style: context.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              SizedBox(
                height: 135,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final item = _comics[index];
                    return InkWell(
                      onTap: () => context.push('/details/${item.id}'),
                      child: SizedBox(
                        width: 100,
                        child: BaseImage(
                          url: item.thumb.url,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(width: 5),
                  itemCount: _comics.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final _handler = fetchFavoriteComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch favorite comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch favorite comics error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    _handler
      ..addListener(_update)
      ..run(UserFavoritePayload(page: 1, sort: ComicSortType.dd));
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
    final comics = _handler.data?.comics.docs ?? [];
    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.push('/favorites'),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Row(
                spacing: 10,
                children: [
                  const Icon(Icons.star),
                  Text('收藏漫画', style: context.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              SizedBox(
                height: 135,
                child: BasePage(
                  isLoading: _handler.isLoading,
                  onRetry: _handler.refresh,
                  error: _handler.error,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = comics[index];
                      return InkWell(
                        onTap: () => context.push('/details/${item.id}'),
                        child: SizedBox(
                          width: 100,
                          child: BaseImage(
                            url: item.thumb.url,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(width: 5),
                    itemCount: comics.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
