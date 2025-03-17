import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/tag.dart';

class ListItem extends StatefulWidget {
  const ListItem({super.key, required this.doc});

  final Doc doc;

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  @override
  Widget build(BuildContext context) {
    final item = widget.doc;
    return InkWell(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      onTap: () {
        context.push('/details/${item.id}');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    item.author,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Expanded(child: _buildCategories(item.categories)),
                  Row(
                    spacing: 10,
                    children: [
                      Text(
                        '${item.totalLikes ?? item.likesCount} likes',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${item.totalViews} views',
                        style: Theme.of(context).textTheme.labelSmall,
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
