import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
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
      padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        const ProFile(),
        const HistoryComics(),
        const Favorites(),
        ListTile(
          onTap: () => context.push('/downloads'),
          leading: const Icon(Icons.download),
          title: Text('我的下载', style: context.textTheme.titleMedium),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: () => context.push('/comments'),
          leading: const Icon(Icons.comment),
          title: Text('我的评论', style: context.textTheme.titleMedium),
          trailing: const Icon(Icons.chevron_right),
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
  late AsyncRequestHandler0<UserProfileResponse> _profileHandler;

  final _punchInHandler = punchIn.useRequest(
    onSuccess: (_, _) {
      Log.info('Punch in success', '');
      showSnackBar('打卡成功');
    },
    onError: (e, _) {
      Log.error('Punch in error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    _profileHandler =
        fetchUserProfile.useRequest(
            onSuccess: (data, _) {
              Log.info('Fetch user profile success', data.toString());
              if (!data.user.isPunched) {
                _punchInHandler.run();
              }
            },
            onError: (e, _) {
              Log.error('Fetch user profile error', e);
            },
          )
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
    return ConstrainedBox(
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
    _helper.addListener(_getHistory);
    super.initState();
  }

  @override
  void dispose() {
    _helper.removeListener(_getHistory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/history'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: Text('最近浏览', style: context.textTheme.titleMedium),
            trailing: const Icon(Icons.chevron_right),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 13),
            child: SizedBox(
              height: 135,
              child:
                  _comics.isEmpty
                      ? const Empty()
                      : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final item = _comics[index];
                          return InkWell(
                            onTap: () => context.push('/details/${item.uid}'),
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
                        separatorBuilder:
                            (context, index) => SizedBox(width: 5),
                        itemCount: _comics.length,
                      ),
            ),
          ),
        ],
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
    return InkWell(
      onTap: () => context.push('/favorites'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.star),
            title: Text('收藏漫画', style: context.textTheme.titleMedium),
            trailing: const Icon(Icons.chevron_right),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 13),
            child: SizedBox(
              height: 135,
              child: BasePage(
                isLoading: _handler.isLoading,
                onRetry: _handler.refresh,
                error: _handler.error,
                child:
                    comics.isEmpty
                        ? const Empty()
                        : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final item = comics[index];
                            return InkWell(
                              onTap: () => context.push('/details/${item.uid}'),
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
                          separatorBuilder:
                              (context, index) => SizedBox(width: 5),
                          itemCount: comics.length,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Empty extends StatelessWidget {
  const Empty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/images/icon_empty.png', width: 100),
    );
  }
}
