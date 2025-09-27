import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/tag.dart';

/// 特别用于搜索展示的item
class SearchListItem extends StatelessWidget {
  const SearchListItem({
    super.key,
    required this.comic,
    required this.blockedWords,
  });

  final SearchComic comic;

  final String? blockedWords;

  @override
  Widget build(BuildContext context) {
    final item = comic;
    if (blockedWords != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.colorScheme.inversePrimary.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '已屏蔽: $blockedWords',
            style: context.textTheme.labelLarge,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: () {
              context.push('/details/${item.id}');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BaseImage(url: item.thumb.url, aspectRatio: 90 / 130),
                  Expanded(
                    child: Column(
                      spacing: 3,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall,
                        ),
                        Text(
                          item.author,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Expanded(child: _buildCategories(item.categories)),
                        Row(
                          spacing: 10,
                          children: [
                            Text(
                              '${formatNumber(item.totalLikes ?? item.likesCount)} likes',
                              style: context.textTheme.labelSmall,
                            ),
                            Text(
                              item.totalViews != null
                                  ? '${formatNumber(item.totalViews!)} views'
                                  : '?? views',
                              style: context.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (item.finished)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                '完结',
                style: context.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(List<String> categories) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: categories.map((e) => Tag(tag: e)).toList(),
      ),
    );
  }
}
