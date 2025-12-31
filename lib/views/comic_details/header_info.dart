import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/comic_details/icon_text.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class ComicHeaderInfo extends StatelessWidget {
  const ComicHeaderInfo({
    super.key,
    required this.data,
  });

  final Comic data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        UiImage(
          borderRadius: BorderRadius.circular(12.0),
          shape: BoxShape.rectangle,
          url: data.thumb.url,
          height: 170,
          width: 115,
          cacheWidth: 115,
          filterQuality: FilterQuality.medium,
        ),
        Expanded(
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: context.textTheme.titleMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (data.author?.isNotEmpty == true)
                _InfoRow(
                  onTap: () => context.push('/comics?a=${data.author}'),
                  data: data.author,
                  icon: Icons.person,
                ),
              if (data.chineseTeam.isNotEmpty == true)
                _InfoRow(
                  onTap: () => context.push('/comics?ct=${data.chineseTeam}'),
                  data: data.chineseTeam,
                  icon: Icons.translate,
                ),
              Row(
                spacing: 10,
                children: [
                  IconText(
                    icon: const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    text: formatNumber(
                      data.totalLikes,
                    ),
                  ),
                  IconText(
                    icon: const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.amber,
                    ),
                    text: formatNumber(
                      data.totalViews,
                    ),
                  ),
                  IconText(
                    icon: const Icon(
                      Icons.image,
                      size: 16,
                      color: Colors.green,
                    ),
                    text: formatNumber(data.pagesCount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.data,
    this.onTap,
    required this.icon,
  });

  final String? data;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(icon, size: 14, color: context.colorScheme.primary),
          Expanded(
            child: Text(
              data ?? '',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
