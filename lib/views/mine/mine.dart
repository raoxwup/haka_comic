import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/user_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:provider/provider.dart';

class Mine extends StatefulWidget {
  const Mine({super.key});

  @override
  State<Mine> createState() => _MineState();
}

class _MineState extends State<Mine> {
  @override
  void initState() {
    super.initState();
    context.read<UserProvider>().userProfileHandler.run();
  }

  @override
  void dispose() {
    context.read<UserProvider>().handlerDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserProvider, User?>((value) => value.user);
    final userProfileHandler = context.read<UserProvider>().userProfileHandler;
    return BasePage(
      isLoading: userProfileHandler.isLoading,
      onRetry: userProfileHandler.refresh,
      error: userProfileHandler.error,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        children: [
          ProFile(user: user),
          const HistoryComics(),
          const Favorites(),
          const _MenuItem(
            icon: Icons.download,
            title: '我的下载',
            route: '/downloads',
          ),
          _MenuItem(
            icon: Icons.comment,
            title: '我的评论',
            route: '/personal_comments',
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push(route),
      leading: Icon(icon),
      title: Text(title, style: context.textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class ProFile extends StatelessWidget {
  const ProFile({super.key, required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200 + context.top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                  tileMode: TileMode.mirror,
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.transparent, context.colorScheme.surface],
                      stops: [0.0, 0.5],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image:
                            user?.avatar?.url != null
                                ? CachedNetworkImageProvider(
                                  user?.avatar?.url ?? '',
                                )
                                : const AssetImage('assets/images/login.png'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 模糊背景层
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: context.top),
              BaseImage(
                url: user?.avatar?.url ?? '',
                width: 80,
                height: 80,
                shape: const CircleBorder(),
              ),
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
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  user?.slogan ?? '~~',
                  style: context.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Positioned(
            right: 10,
            top: 10 + context.top,
            child: IconButton(
              onPressed: () => context.push('/personal_editor'),
              icon: Icon(Icons.drive_file_rename_outline),
            ),
          ),
        ],
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

  Future<void> _getHistory() async {
    final comics = await _helper.query(1);
    setState(() => _comics = comics);
  }

  @override
  void initState() {
    super.initState();
    _getHistory();
    _helper.addListener(_getHistory);
  }

  @override
  void dispose() {
    _helper.removeListener(_getHistory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ComicSection(
      title: '最近浏览',
      icon: Icons.history,
      route: '/history',
      isEmpty: _comics.isEmpty,
      itemCount: _comics.length,
      onRetry: () {},
      itemBuilder: (context, index) {
        final item = _comics[index];
        return _ComicItem(url: item.thumb.url, uid: item.uid);
      },
    );
  }
}

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  late final _handler = fetchFavoriteComics.useRequest(
    onSuccess:
        (data, _) => Log.info('Fetch favorite comics success', data.toString()),
    onError: (e, _) => Log.error('Fetch favorite comics error', e),
  );

  @override
  void initState() {
    super.initState();
    _handler
      ..addListener(() => setState(() {}))
      ..run(UserFavoritePayload(page: 1, sort: ComicSortType.dd));
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comics = _handler.data?.comics.docs ?? [];
    return _ComicSection(
      title: '收藏漫画',
      icon: Icons.star,
      route: '/favorites',
      isEmpty: comics.isEmpty,
      isLoading: _handler.isLoading,
      error: _handler.error,
      onRetry: _handler.refresh,
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final item = comics[index];
        return _ComicItem(url: item.thumb.url, uid: item.uid);
      },
    );
  }
}

class _ComicSection extends StatelessWidget {
  const _ComicSection({
    required this.title,
    required this.icon,
    required this.route,
    required this.isEmpty,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRetry,
    this.isLoading = false,
    this.error,
  });

  final String title;
  final IconData icon;
  final String route;
  final bool isEmpty;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title, style: context.textTheme.titleMedium),
            trailing: const Icon(Icons.chevron_right),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 13),
            child: SizedBox(
              height: 135,
              child:
                  error != null || isLoading
                      ? BasePage(
                        isLoading: isLoading,
                        onRetry: onRetry,
                        error: error,
                        errorBuilder:
                            (_) => Center(
                              child: IconButton(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh),
                              ),
                            ),
                        child: isEmpty ? const Empty() : _buildList(),
                      )
                      : isEmpty
                      ? const Empty()
                      : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: itemBuilder,
      separatorBuilder: (_, __) => const SizedBox(width: 5),
      itemCount: itemCount,
    );
  }
}

class _ComicItem extends StatelessWidget {
  const _ComicItem({required this.url, required this.uid});

  final String url;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/details/$uid'),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 100,
        child: BaseImage(
          url: url,
          width: double.infinity,
          height: double.infinity,
        ),
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
