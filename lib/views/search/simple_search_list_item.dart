import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';

class SimpleSearchListItem extends StatelessWidget {
  const SimpleSearchListItem({super.key, required this.comic});

  final SearchComic comic;

  @override
  Widget build(BuildContext context) {
    final item = comic;

    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: () {
              context.push('/details/${item.uid}');
            },
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 3,
                  children: [
                    BaseImage(url: item.thumb.url, aspectRatio: 1 / 1.4),
                    Text(
                      item.title,
                      style: context.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (item.finished)
          Positioned(
            top: 4,
            right: 4,
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
}
