import 'dart:io';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart' as models;
// import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/views/comics/comics.dart';
import 'package:haka_comic/views/comics/search_comics.dart';
import 'package:haka_comic/views/comments/comments.dart';
import 'package:haka_comic/views/comments/sub_comments.dart';
import 'package:haka_comic/views/home/home.dart';
import 'package:haka_comic/views/login/login.dart';
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
import 'package:haka_comic/views/settings/settings.dart';

// const MethodChannel platform = MethodChannel('back_to_home');

// Future<void> _moveToBackground() async {
//   try {
//     await platform.invokeMethod('moveToBackground');
//   } on PlatformException catch (e) {
//     Log.error("Failed to move to background", e);
//   }
// }

// 路由配置
final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  redirect: (context, state) {
    if (AppConf.instance.isLogged) {
      return null;
    }
    return '/login';
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
  ],
);

Page<dynamic> customTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return Platform.isIOS
      ? CupertinoPage(child: child, key: state.pageKey)
      : CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 主页面滑动动画
          final slideAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          // 次级页面淡出动画
          final fadeAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
            CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
          );

          return RepaintBoundary(
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(opacity: fadeAnimation, child: child),
            ),
          );
        },
      );
}

void logout() {
  AppConf.instance.clearAuth();
  appRouter.go('/login');
}
