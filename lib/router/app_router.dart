import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/views/comics/comics.dart';
import 'package:haka_comic/views/comments/comments.dart';
import 'package:haka_comic/views/home/home.dart';
import 'package:haka_comic/views/login/login.dart';

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
      builder: (BuildContext context, GoRouterState state) {
        return const Home();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const Login();
      },
    ),
    GoRoute(
      path: '/comics',
      builder: (BuildContext context, GoRouterState state) {
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
      builder: (BuildContext context, GoRouterState state) {
        return ComicDetails(id: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      path: '/comments/:id',
      builder: (BuildContext context, GoRouterState state) {
        return CommentsPage(id: state.pathParameters['id']!);
      },
    ),
  ],
);

void logout() {
  AppConfig().token = '';
  appRouter.go('/login');
}
