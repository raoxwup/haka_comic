import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:go_router/go_router.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final handler = fetchCategories.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch categories success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch categories failed', e);
    },
  );

  @override
  void initState() {
    handler
      ..addListener(_update)
      ..run();
    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      isLoading: handler.isLoading,
      onRetry: handler.refresh,
      error: handler.error,
      child: _buildCategoryList(),
    );
  }

  Widget _buildCategoryList() {
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
      padding: EdgeInsets.all(8.0),
      itemCount: handler.data?.categories.length ?? 0,
      itemBuilder: (context, index) {
        final item = handler.data!.categories[index];
        return _buildItem(item);
      },
    );
  }

  Widget _buildItem(Category item) {
    return InkWell(
      onTap: () {
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
