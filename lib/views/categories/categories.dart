import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:go_router/go_router.dart';

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

class _CategoriesState extends State<Categories> with AutoRegisterHandlerMixin {
  final handler = fetchCategories.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch categories success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch categories failed', e);
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [handler];

  @override
  void initState() {
    super.initState();
    handler.run();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      isLoading: handler.isLoading || !widget.isRouteAnimationCompleted,
      onRetry: handler.refresh,
      error: handler.error,
      child: _buildCategoryList(),
    );
  }

  Widget _buildCategoryList() {
    final categories = handler.data?.categories ?? [];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent:
            UiMode.m1(context)
                ? 130
                : UiMode.m2(context)
                ? 135
                : 140,
        mainAxisSpacing: 5,
        crossAxisSpacing: 3,
        childAspectRatio: 1 / 1.3,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: extraMenus.length + categories.length,
      itemBuilder: (context, index) {
        if (index < extraMenus.length) return _buildMenuItem(extraMenus[index]);
        final item = categories[index - extraMenus.length];
        return _buildItem(item);
      },
    );
  }

  Widget _buildMenuItem(Map<String, String> item) {
    return InkWell(
      onTap: () {
        context.push(item['path']!);
      },
      borderRadius: BorderRadius.circular(6),
      child: SingleChildScrollView(
        child: Column(
          spacing: 5,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Card(
                clipBehavior: Clip.hardEdge,
                elevation: 0,
                child: Image.asset(item['icon']!),
              ),
            ),
            Text(item['title']!, style: context.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Category item) {
    return InkWell(
      onTap: () {
        if (item.isWeb ?? false) return;
        context.push('/comics?c=${item.title}');
      },
      borderRadius: BorderRadius.circular(6),
      child: SingleChildScrollView(
        child: Column(
          spacing: 5,
          children: [
            BaseImage(url: item.thumb.url, aspectRatio: 1),
            Text(item.title, style: context.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
