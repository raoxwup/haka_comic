import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart' as models;
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/views/comics/comics.dart';
import 'package:haka_comic/views/comics/search_comics.dart';
import 'package:haka_comic/views/comments/comments.dart';
import 'package:haka_comic/views/comments/sub_comments.dart';
import 'package:haka_comic/views/home/home.dart';
import 'package:haka_comic/views/login/login.dart';
import 'package:haka_comic/views/search/search.dart';
import 'package:haka_comic/views/settings/settings.dart';

// 路由配置
final GoRouter appRouter = GoRouter(
  redirect: (context, state) {
    if (AppConfig.isLogged) {
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
          final slideAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          final secondarySlideAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.3, 0.0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            ),
          );

          return SlideTransition(
            position: slideAnimation,
            child: SlideTransition(
              position: secondarySlideAnimation,
              child: child,
            ),
          );
        },
      );
}

void logout() {
  AppConfig().token = '';
  appRouter.go('/login');
}
