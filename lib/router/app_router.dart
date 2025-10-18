import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart' as models;
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/views/about/about.dart';
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/views/comic_details/downloader.dart';
import 'package:haka_comic/views/comics/comics.dart';
import 'package:haka_comic/views/notifications/notifications.dart';
import 'package:haka_comic/views/search/search_comics.dart';
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
import 'package:haka_comic/views/settings/tag_block.dart';
import 'package:haka_comic/views/settings/visible_categories.dart';
import 'package:haka_comic/views/settings/settings.dart';
import 'package:haka_comic/views/settings/webdav.dart';
import 'package:haka_comic/views/settings/word_block.dart';

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
    GoRoute(
      path: '/comments/:id',
      builder: (_, state) => CommentsPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/sub_comments',
      builder: (_, state) =>
          SubCommentsPage(comment: state.extra as models.Comment),
    ),
    GoRoute(path: '/search', builder: (_, _) => const Search()),
    GoRoute(path: '/settings', builder: (_, _) => const Settings()),
    GoRoute(
      path: '/search_comics',
      builder: (_, state) =>
          SearchComics(keyword: state.uri.queryParameters['keyword']!),
    ),
    GoRoute(path: '/reader', builder: (_, _) => const Reader()),
    GoRoute(path: '/rank', builder: (_, _) => const Rank()),
    GoRoute(path: '/random', builder: (_, _) => const Random()),
    GoRoute(path: '/favorites', builder: (_, _) => const Favorites()),
    GoRoute(path: '/history', builder: (_, _) => const History()),
    GoRoute(path: '/downloads', builder: (_, _) => const Downloads()),
    GoRoute(path: '/personal_comments', builder: (_, _) => const Comments()),
    GoRoute(
      path: '/personal_sub_comments',
      builder: (_, state) {
        final extra = state.extra as Map;
        final comment = extra['comment'] as models.PersonalComment;
        final user = extra['user'] as models.User;
        return PersonalSubComment(comment: comment, user: user);
      },
    ),
    GoRoute(path: '/personal_editor', builder: (_, _) => const Editor()),
    GoRoute(
      path: '/downloader',
      builder: (_, state) {
        final extra = state.extra as Map;
        final DownloadComic downloadComic =
            extra['downloadComic'] as DownloadComic;
        final chapters = extra['chapters'] as List<models.Chapter>;
        return Downloader(chapters: chapters, downloadComic: downloadComic);
      },
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
  ],
);

void logout() {
  AppConf.instance.clearAuth();
  appRouter.go('/login');
}
