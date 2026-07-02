import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/mine/comic_preview_section.dart';
import 'package:haka_comic/views/mine/profile.dart';

class Mine extends StatefulWidget {
  const Mine({super.key});

  @override
  State<Mine> createState() => _MineState();
}

class _MineState extends State<Mine> {
  @override
  void initState() {
    super.initState();
    context.userReader.userHandler.run();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.userSelector((p) => p.userHandler.state);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        _ProfileHeader(state: state),
        const HistoryComics(),
        const Favorites(),
        const _MenuItem(
          icon: Icons.download,
          title: '我的下载',
          route: '/downloads',
        ),
        const _MenuItem(
          icon: Icons.comment,
          title: '我的评论',
          route: '/personal_comments',
        ),
        const _MenuItem(
          icon: Icons.bookmark,
          title: '本地收藏夹',
          route: '/local_favorites',
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state});

  final RequestState<UserProfileResponse> state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Success(:final data) => ProFile(user: data.user),
      Error() => _ProfileErrorHeader(
        onRetry: context.userReader.userHandler.refresh,
      ),
      _ => const _ProfileLoadingHeader(),
    };
  }
}

class _ProfileLoadingHeader extends StatelessWidget {
  const _ProfileLoadingHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200 + context.top,
      child: Padding(
        padding: .only(top: context.top),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProfileErrorHeader extends StatelessWidget {
  const _ProfileErrorHeader({required this.onRetry});

  final VoidCallback onRetry;

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
                      colors: [
                        Colors.transparent,
                        context.colorScheme.surface,
                        context.colorScheme.surface.withValues(alpha: 0.3),
                      ],
                      stops: const [0.02, 0.5, 0.85],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/default_avatar.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: .only(top: context.top),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/default_avatar.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('加载失败', style: context.textTheme.titleMedium),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onRetry,
                      tooltip: '重新加载',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
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

class HistoryComics extends StatefulWidget {
  const HistoryComics({super.key});

  @override
  State<HistoryComics> createState() => _HistoryComicsState();
}

class _HistoryComicsState extends State<HistoryComics> {
  final _helper = HistoryHelper();
  List<HistoryDoc> _comics = [];
  int? _comicsCount;

  Future<void> _getHistory() async {
    final comics = await _helper.query(1);
    final count = await _helper.count();
    setState(() {
      _comics = comics;
      _comicsCount = count;
    });
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
    return ComicSection(
      title: '最近浏览',
      icon: Icons.history,
      route: '/history',
      isEmpty: _comics.isEmpty,
      itemCount: _comics.length,
      onRetry: () {},
      count: _comicsCount,
      itemBuilder: (context, index) {
        final item = _comics[index];
        return ComicItem(
          url: item.thumb.url,
          cacheKey: item.thumb.cacheKey,
          uid: item.uid,
        );
      },
    );
  }
}

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> with RequestMixin {
  late final _handler = fetchFavoriteComics.useRequest(
    defaultParams: UserFavoritePayload(page: 1, sort: ComicSortType.dd),
    onSuccess: (data, _) =>
        Log.i('Fetch favorite comics success', data.toString()),
    onError: (e, _) => Log.e('Fetch favorite comics error', error: e),
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    final comics = _handler.state.data?.comics.docs ?? [];
    return ComicSection(
      title: '收藏漫画',
      icon: Icons.star,
      route: '/favorites',
      isEmpty: comics.isEmpty,
      isLoading: _handler.state.loading,
      error: _handler.state.error,
      onRetry: _handler.refresh,
      itemCount: comics.length,
      count: _handler.state.data?.comics.total,
      itemBuilder: (context, index) {
        final item = comics[index];
        return ComicItem(
          url: item.thumb.url,
          cacheKey: item.thumb.cacheKey,
          uid: item.uid,
        );
      },
    );
  }
}
