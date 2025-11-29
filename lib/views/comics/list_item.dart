import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/tag.dart';

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.doc,
    this.isSelected = false,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final ComicBase doc;

  final bool isSelected;

  final void Function(TapDownDetails)? onTapDown;

  final void Function(TapDownDetails)? onSecondaryTapDown;

  final void Function(Doc)? onLongPress;

  final void Function()? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final item = doc;

    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: () {
              context.push('/details/${item.uid}');
            },
            onTapDown: onTapDown,
            onSecondaryTapDown: onSecondaryTapDown,
            onLongPress: item is Doc ? () => onLongPress?.call(item) : null,
            onSecondaryTap: onSecondaryTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: isSelected
                  ? BoxDecoration(
                      color: context.colorScheme.secondaryContainer.withValues(
                        alpha: 0.65,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BaseImage(url: doc.thumb.url, aspectRatio: 90 / 130),
                  Expanded(
                    child: Column(
                      spacing: 3,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item is Doc
                              ? '[${item.pagesCount}P]${item.title}'
                              : item.title,
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
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatNumber(item.totalLikes ?? item.likesCount),
                              style: context.textTheme.labelSmall,
                            ),
                            if (item.totalViews != null) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatNumber(item.totalViews!),
                                style: context.textTheme.labelSmall,
                              ),
                            ],
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
