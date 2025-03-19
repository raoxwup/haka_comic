import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/widgets/base_image.dart';

class ComicCreator extends StatelessWidget {
  const ComicCreator({
    super.key,
    required this.creator,
    required this.updatedAt,
  });

  final Creator? creator;

  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    final String time =
        updatedAt == null
            ? ''
            : DateTime.parse(updatedAt!).toString().split(' ')[0];
    return InkWell(
      onTap: () => showCreator(context, creator),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Row(
          spacing: 8,
          children: [
            BaseImage(
              shape: const CircleBorder(),
              url: creator?.avatar?.url ?? '',
              width: 40,
              height: 40,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  creator?.name ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
