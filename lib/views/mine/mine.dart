import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/error_page.dart';
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
          const _MenuItem(
            icon: Icons.bookmark,
            title: '本地收藏夹',
            route: '/local_favorites',
          ),
          const _MenuItem(
            icon: Icons.file_upload,
            title: '本地导入',
            route: '/import_comics',
          ),
        ],
      ),
      Error(:final error) => Padding(
        padding: .only(top: context.top),
        child: ErrorPage(
          errorMessage: error.toString(),
          onRetry: context.userReader.userHandler.refresh,
          extraButton: TextButton(
            onPressed: () => context.push('/downloads'),
            child: const Text('我的下载'),
          ),
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
