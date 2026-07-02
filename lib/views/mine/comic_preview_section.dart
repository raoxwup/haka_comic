import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/tag.dart';
import 'package:haka_comic/widgets/ui_image.dart';

const double _kPreviewHeight = 135;
const double _kComicItemWidth = 100;

class ComicSection extends StatelessWidget {
  const ComicSection({
    super.key,
    required this.title,
    required this.icon,
    required this.route,
    required this.isEmpty,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRetry,
    this.isLoading = false,
    this.error,
    this.count,
  });

  final String title;
  final IconData icon;
  final String route;
  final bool isEmpty;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title, style: context.textTheme.titleMedium),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count != null) Tag(tag: count.toString()),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 13),
            child: SizedBox(
              height: _kPreviewHeight,
              child: BasePage(
                isLoading: isLoading,
                onRetry: onRetry,
                error: error,
                errorBuilder: (_) => Center(
                  child: IconButton(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                child: isEmpty
                    ? const Empty(
                        imageWidth: _kComicItemWidth,
                        height: double.infinity,
                      )
                    : _buildList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: itemBuilder,
      separatorBuilder: (_, _) => const SizedBox(width: 5),
      itemCount: itemCount,
    );
  }
}

class ComicItem extends StatelessWidget {
  const ComicItem({
    super.key,
    required this.url,
    required this.uid,
    this.cacheKey,
  });

  final String url;
  final String uid;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/details/$uid'),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _kComicItemWidth,
        child: UiImage(
          url: url,
          cacheKey: cacheKey,
          cacheWidth: 150,
          shape: .rectangle,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
