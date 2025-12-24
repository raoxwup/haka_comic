import 'dart:async';
import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/utils/extension.dart' hide UseRequest1Extensions;
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/tag.dart';
import 'package:haka_comic/widgets/ui_image.dart';

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
    return switch (state) {
      Success(:final data) => ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        children: [
          ProFile(user: data.user),
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
        ],
      ),
      Error(:final error) => Padding(
        padding: .only(top: context.top),
        child: ErrorPage(
          errorMessage: error.toString(),
          onRetry: context.userReader.userHandler.refresh,
        ),
      ),
      _ => Padding(
        padding: .only(top: context.top),
        child: const Center(child: CircularProgressIndicator()),
      ),
    };
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

  final User user;

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
                      stops: [0.02, 0.5, 0.85],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: user.avatar != null
                            ? ExtendedNetworkImageProvider(
                                user.avatar!.url,
                                cache: true,
                              )
                            : const AssetImage(
                                'assets/images/default_avatar.jpg',
                              ),
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
              user.avatar != null
                  ? UiImage(
                      url: user.avatar!.url,
                      width: 80,
                      height: 80,
                      shape: .circle,
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundColor: context.colorScheme.surface,
                      backgroundImage: const AssetImage(
                        'assets/images/default_avatar.jpg',
                      ),
                    ),
              Text(
                user.name,
                style: context.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Lv.${user.level}  Exp: ${user.exp}',
                style: context.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  user.slogan,
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
              icon: const Icon(Icons.drive_file_rename_outline),
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
    return _ComicSection(
      title: '最近浏览',
      icon: Icons.history,
      route: '/history',
      isEmpty: _comics.isEmpty,
      itemCount: _comics.length,
      onRetry: () {},
      count: _comicsCount,
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

class _FavoritesState extends State<Favorites> with RequestMixin {
  late final _handler = fetchFavoriteComics.useRequest(
    defaultParams: UserFavoritePayload(page: 1, sort: ComicSortType.dd),
    onSuccess: (data, _) =>
        Log.info('Fetch favorite comics success', data.toString()),
    onError: (e, _) => Log.error('Fetch favorite comics error', e),
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    final comics = _handler.state.data?.comics.docs ?? [];
    return _ComicSection(
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
    this.count,
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
  final int? count;

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count != null) Tag(tag: count.toString()),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 13),
            child: SizedBox(
              height: 135,
              child: error != null || isLoading
                  ? BasePage(
                      isLoading: isLoading,
                      onRetry: onRetry,
                      error: error,
                      errorBuilder: (_) => Center(
                        child: IconButton(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                      child: isEmpty
                          ? const Empty(
                              imageWidth: 100,
                              height: double.infinity,
                            )
                          : _buildList(),
                    )
                  : isEmpty
                  ? const Empty(imageWidth: 100, height: double.infinity)
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
      separatorBuilder: (_, _) => const SizedBox(width: 5),
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
        child: UiImage(
          url: url,
          cacheWidth: 150,
          shape: .rectangle,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
