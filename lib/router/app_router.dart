import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/home.dart';
import 'package:haka_comic/views/login.dart';

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
  ],
);

void goLogin() {
  AppConfig().token = '';
  appRouter.replace('/login');
}
