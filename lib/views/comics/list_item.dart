import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/tag.dart';

class ListItem extends StatefulWidget {
  const ListItem({
    super.key,
    required this.doc,
    this.isSelected = false,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final Doc doc;

  final bool isSelected;

  final void Function(TapDownDetails)? onTapDown;

  final void Function(TapDownDetails)? onSecondaryTapDown;

  final void Function()? onLongPress;

  final void Function()? onSecondaryTap;

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  @override
  Widget build(BuildContext context) {
    final item = widget.doc;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: () {
        context.push('/details/${item.uid}');
      },
      onTapDown: widget.onTapDown,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onLongPress: widget.onLongPress,
      onSecondaryTap: widget.onSecondaryTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration:
            widget.isSelected
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
            BaseImage(url: widget.doc.thumb.url, aspectRatio: 90 / 130),
            Expanded(
              child: Column(
                spacing: 3,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[${item.pagesCount}P]${item.title}',
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
                        '${formatNumber(item.totalViews)} views',
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
