import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart' show Comment, Chapter;
import 'package:haka_comic/router/route_observer.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/about/about.dart';
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/views/comic_details/downloader.dart';
import 'package:haka_comic/views/comics/comics.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/views/download/downloads_ui.dart';
import 'package:haka_comic/views/notifications/notifications.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/views/search/search_comics.dart';
import 'package:haka_comic/views/comments/comments.dart';
import 'package:haka_comic/views/comments/sub_comments.dart';
import 'package:haka_comic/views/home/home.dart';
import 'package:haka_comic/views/login/login.dart';
import 'package:haka_comic/views/login/register.dart';
import 'package:haka_comic/views/mine/comments.dart';
import 'package:haka_comic/views/mine/editor.dart';
import 'package:haka_comic/views/mine/favorites.dart';
import 'package:haka_comic/views/mine/history.dart';
import 'package:haka_comic/views/random/random.dart' show Random;
import 'package:haka_comic/views/rank/rank.dart';
import 'package:haka_comic/views/reader/reader.dart';
import 'package:haka_comic/views/search/search.dart';
import 'package:haka_comic/views/settings/blacklist.dart';
import 'package:haka_comic/views/settings/gesture_area.dart';
import 'package:haka_comic/views/settings/tag_block.dart';
import 'package:haka_comic/views/settings/visible_categories.dart';
import 'package:haka_comic/views/settings/settings.dart';
import 'package:haka_comic/views/settings/webdav.dart';
import 'package:haka_comic/views/settings/word_block.dart';
import 'package:provider/provider.dart';

Page<dynamic> _buildSideSheetRoutePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  if (UiMode.m1(context)) {
    return MaterialPage(key: state.pageKey, child: child);
  }

  return CustomTransitionPage(
    key: state.pageKey,
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: curvedAnimation,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
                child: Container(color: Colors.black54),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 4,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      );
    },
    child: child,
  );
}

// 路由配置
final GoRouter appRouter = GoRouter(
  observers: [routeObserver],
  navigatorKey: navigatorKey,
  redirect: (context, state) {
    final isLoggedIn = AppConf.instance.isLogged;
    final currentPath = state.matchedLocation; // 获取当前匹配的路由路径

    final allowPaths = ['/login', '/register'];

    if (!isLoggedIn &&
        !allowPaths.any((path) => currentPath.startsWith(path))) {
      return '/login';
    }

    if (isLoggedIn && (currentPath == '/login' || currentPath == '/register')) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, _) => const Home()),
    GoRoute(path: '/login', builder: (_, _) => const Login()),
    GoRoute(path: '/register', builder: (_, _) => const Register()),
    GoRoute(
      path: '/comics',
      builder: (_, state) {
        return Comics(
          c: state.uri.queryParameters['c'],
          t: state.uri.queryParameters['t'],
          ca: state.uri.queryParameters['ca'],
          a: state.uri.queryParameters['a'],
          ct: state.uri.queryParameters['ct'],
        );
      },
    ),
    GoRoute(
      path: '/details/:id',
      builder: (_, state) => ComicDetails(id: state.pathParameters['id']!),
    ),
    ShellRoute(
      pageBuilder: (context, state, child) =>
          _buildSideSheetRoutePage(context, state, child),
      routes: [
        GoRoute(
          path: '/comments/:id',
          builder: (_, state) => CommentsPage(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'sub_comments',
              builder: (_, state) =>
                  SubCommentsPage(comment: state.extra as Comment),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/search', builder: (_, _) => const Search()),
    GoRoute(path: '/settings', builder: (_, _) => const Settings()),
    GoRoute(
      path: '/search_comics',
      builder: (_, state) =>
          SearchComics(keyword: state.uri.queryParameters['keyword']!),
    ),
    GoRoute(
      path: '/reader',
      builder: (_, s) {
        final state = s.extra as ComicState;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ReaderProvider(state: state)),
            ChangeNotifierProvider(create: (_) => ListStateProvider()),
          ],
          child: const Reader(),
        );
      },
    ),
    GoRoute(path: '/rank', builder: (_, _) => const Rank()),
    GoRoute(path: '/random', builder: (_, _) => const Random()),
    GoRoute(path: '/favorites', builder: (_, _) => const Favorites()),
    GoRoute(path: '/history', builder: (_, _) => const History()),
    GoRoute(path: '/downloads', builder: (_, _) => const Downloads()),
    ShellRoute(
      pageBuilder: (context, state, child) =>
          _buildSideSheetRoutePage(context, state, child),
      routes: [
        GoRoute(
          path: '/personal_comments',
          builder: (_, _) => const Comments(),
          routes: [
            GoRoute(
              path: 'sub_comments',
              builder: (_, state) =>
                  SubCommentsPage(comment: state.extra as Comment),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/personal_editor', builder: (_, _) => const Editor()),
    ShellRoute(
      pageBuilder: (context, state, child) =>
          _buildSideSheetRoutePage(context, state, child),
      routes: [
        GoRoute(
          path: '/downloader',
          builder: (_, state) {
            final extra = state.extra as Map;
            final DownloadComic downloadComic =
                extra['downloadComic'] as DownloadComic;
            final chapters = extra['chapters'] as List<Chapter>;
            return Downloader(chapters: chapters, downloadComic: downloadComic);
          },
        ),
      ],
    ),
    GoRoute(path: '/about', builder: (_, _) => const About()),
    GoRoute(path: '/blacklist', builder: (_, _) => const Blacklist()),
    GoRoute(
      path: '/visible_categories',
      builder: (_, _) => const VisibleCategories(),
    ),
    GoRoute(path: '/webdav', builder: (_, _) => const WebDAV()),
    GoRoute(path: '/notifications', builder: (_, _) => const Notifications()),
    GoRoute(path: '/tag_block', builder: (_, _) => const TagBlock()),
    GoRoute(path: '/word_block', builder: (_, _) => const WordBlock()),
    GoRoute(
      path: '/gesture_area',
      builder: (_, _) => const GestureArea(),
      routes: [
        GoRoute(
          path: 'details/:type',
          builder: (_, state) {
            final type = GestureAreaType.fromName(state.pathParameters['type']);
            return GestureAreaDetails(type: type);
          },
        ),
      ],
    ),
  ],
);

void logout() {
  AppConf.instance.clearAuth();
  appRouter.go('/login');
}
