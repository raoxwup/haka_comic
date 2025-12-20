import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart' hide UseRequestExtensions;
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class Categories extends StatefulWidget {
  const Categories({super.key, required this.isRouteAnimationCompleted});

  final bool isRouteAnimationCompleted;

  @override
  State<Categories> createState() => _CategoriesState();
}

const extraMenus = [
  {"title": "排行榜", "path": "/rank", "icon": "assets/images/leaderboard.jpg"},
  {
    "title": "留言板",
    "path": "/comments/5822a6e3ad7ede654696e482",
    "icon": "assets/images/forum.jpg",
  },
  {"title": "最近更新", "path": "/comics", "icon": "assets/images/latest.jpg"},
  {"title": "随机本子", "path": "/random", "icon": "assets/images/random.jpg"},
];

class _CategoriesState extends State<Categories> with RequestMixin {
  final handler = fetchCategories.useRequest(
    onSuccess: (data) {
      Log.info('Fetch categories success', data.toString());
    },
    onError: (e) {
      Log.error('Fetch categories failed', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [handler];

  @override
  Widget build(BuildContext context) {
    return switch (handler.state) {
      Success(:final data) => _buildCategoryList(data.categories),
      Error(:final error) => ErrorPage(
        errorMessage: error.toString(),
        onRetry: handler.refresh,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildCategoryList(List<Category> categories) {
    final visibleExtraMenus = List.of(extraMenus);
    final visibleCategories = List<Category>.of(categories);
    if (AppConf().visibleCategories.isNotEmpty) {
      visibleExtraMenus.removeWhere(
        (item) => !AppConf().visibleCategories.contains(item['title']),
      );
      visibleCategories.removeWhere(
        (item) => !AppConf().visibleCategories.contains(item.title),
      );
    }
    return GridView.builder(
      cacheExtent: context.height * 1.5,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: UiMode.m1(context)
            ? 130
            : UiMode.m2(context)
            ? 135
            : 140,
        mainAxisSpacing: 5,
        crossAxisSpacing: 3,
        childAspectRatio: 1 / 1.4,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: visibleExtraMenus.length + visibleCategories.length,
      itemBuilder: (context, index) {
        if (index < visibleExtraMenus.length) {
          return _buildMenuItem(visibleExtraMenus[index]);
        }
        final item = visibleCategories[index - visibleExtraMenus.length];
        return _buildItem(item);
      },
    );
  }

  Widget _buildMenuItem(Map<String, String> item) {
    return InkWell(
      key: ValueKey(item['title']),
      onTap: () => context.push(item['path']!),
      borderRadius: BorderRadius.circular(6),
      child: Column(
        spacing: 5,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Card(
              clipBehavior: .hardEdge,
              elevation: 0,
              child: Image.asset(item['icon']!),
            ),
          ),
          Text(item['title']!, style: context.textTheme.labelLarge),
        ],
      ),
    );
  }

  Widget _buildItem(Category item) {
    return InkWell(
      key: ValueKey(item.title),
      onTap: () {
        if (item.isWeb ?? false) return;
        context.push('/comics?c=${item.title}');
      },
      borderRadius: BorderRadius.circular(6),
      child: Column(
        spacing: 5,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Card(
              clipBehavior: .hardEdge,
              elevation: 0,
              child: UiImage(
                url: item.thumb.url,
                filterQuality: .medium,
                cacheWidth: 150,
              ),
            ),
          ),
          Text(item.title, style: context.textTheme.labelLarge),
        ],
      ),
    );
  }
}
