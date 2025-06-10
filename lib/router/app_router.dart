import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart' as models;
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/views/about/about.dart';
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/views/comic_details/downloader.dart';
import 'package:haka_comic/views/comics/comics.dart';
import 'package:haka_comic/views/comics/search_comics.dart';
import 'package:haka_comic/views/comments/comments.dart';
import 'package:haka_comic/views/comments/sub_comments.dart';
import 'package:haka_comic/views/home/home.dart';
import 'package:haka_comic/views/login/login.dart';
import 'package:haka_comic/views/login/register.dart';
import 'package:haka_comic/views/mine/comments/comments.dart';
import 'package:haka_comic/views/mine/comments/sub_comments.dart';
import 'package:haka_comic/views/mine/downloads.dart';
import 'package:haka_comic/views/mine/editor.dart';
import 'package:haka_comic/views/mine/favorites.dart';
import 'package:haka_comic/views/mine/history.dart';
import 'package:haka_comic/views/random/random.dart' show Random;
import 'package:haka_comic/views/rank/rank.dart';
import 'package:haka_comic/views/reader/reader.dart';
import 'package:haka_comic/views/search/search.dart';
import 'package:haka_comic/views/settings/blacklist.dart';
import 'package:haka_comic/views/settings/settings.dart';

// 路由配置
final GoRouter appRouter = GoRouter(
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
    GoRoute(
      path: '/',
      pageBuilder:
          (context, state) => customTransitionPage(
            context: context,
            state: state,
            child: const Home(),
          ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Login(),
        );
      },
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Register(),
        );
      },
    ),
    GoRoute(
      path: '/comics',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: Comics(
            c: state.uri.queryParameters['c'],
            t: state.uri.queryParameters['t'],
            ca: state.uri.queryParameters['ca'],
            a: state.uri.queryParameters['a'],
            ct: state.uri.queryParameters['ct'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/details/:id',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: ComicDetails(id: state.pathParameters['id']!),
        );
      },
    ),
    GoRoute(
      path: '/comments/:id',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: CommentsPage(id: state.pathParameters['id']!),
        );
      },
    ),
    GoRoute(
      path: '/sub_comments',
      pageBuilder: (context, state) {
        final models.Comment comment = state.extra as models.Comment;
        return customTransitionPage(
          context: context,
          state: state,
          child: SubCommentsPage(comment: comment),
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Search(),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Settings(),
        );
      },
    ),
    GoRoute(
      path: '/search_comics',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: SearchComics(keyword: state.uri.queryParameters['keyword']!),
        );
      },
    ),
    GoRoute(
      path: '/reader/:id/:chapterId/:pageNo',
      pageBuilder: (context, state) {
        final extra = state.extra as Map;
        final List<models.Chapter> chapters =
            extra['chapters'] as List<models.Chapter>;
        final title = extra['title'] as String;
        return customTransitionPage(
          context: context,
          state: state,
          child: Reader(
            id: state.pathParameters['id']!,
            chapters: chapters,
            chapterId: state.pathParameters['chapterId']!,
            pageNo: int.tryParse(state.pathParameters['pageNo']!) ?? 0,
            title: title,
          ),
        );
      },
    ),
    GoRoute(
      path: '/rank',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Rank(),
        );
      },
    ),
    GoRoute(
      path: '/random',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Random(),
        );
      },
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Favorites(),
        );
      },
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const History(),
        );
      },
    ),
    GoRoute(
      path: '/downloads',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Downloads(),
        );
      },
    ),
    GoRoute(
      path: '/personal_comments',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Comments(),
        );
      },
    ),
    GoRoute(
      path: '/personal_sub_comments',
      pageBuilder: (context, state) {
        final extra = state.extra as Map;
        final comment = extra['comment'] as models.PersonalComment;
        final user = extra['user'] as models.User;
        return customTransitionPage(
          context: context,
          state: state,
          child: PersonalSubComment(comment: comment, user: user),
        );
      },
    ),
    GoRoute(
      path: '/personal_editor',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Editor(),
        );
      },
    ),
    GoRoute(
      path: '/downloader',
      pageBuilder: (context, state) {
        final extra = state.extra as Map;
        final DownloadComic downloadComic =
            extra['downloadComic'] as DownloadComic;
        final chapters = extra['chapters'] as List<models.Chapter>;
        return customTransitionPage(
          context: context,
          state: state,
          child: Downloader(chapters: chapters, downloadComic: downloadComic),
        );
      },
    ),
    GoRoute(
      path: '/about',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const About(),
        );
      },
    ),
    GoRoute(
      path: '/blacklist',
      pageBuilder: (context, state) {
        return customTransitionPage(
          context: context,
          state: state,
          child: const Blacklist(),
        );
      },
    ),
  ],
);

Page<dynamic> customTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CupertinoPage(child: child, key: state.pageKey);
}

void logout() {
  AppConf.instance.clearAuth();
  appRouter.go('/login');
}
