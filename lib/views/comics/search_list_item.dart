import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/tag.dart';

class SearchListItem extends StatefulWidget {
  const SearchListItem({super.key, required this.comic});

  final SearchComic comic;

  @override
  State<SearchListItem> createState() => _SearchListItemState();
}

class _SearchListItemState extends State<SearchListItem> {
  @override
  Widget build(BuildContext context) {
    final item = widget.comic;
    return InkWell(
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
