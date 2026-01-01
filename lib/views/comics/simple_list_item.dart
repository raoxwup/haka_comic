import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class SimpleListItem extends StatelessWidget {
  const SimpleListItem({
    super.key,
    required this.doc,
    this.contextMenu,
    this.onItemSelected,
    this.enableDefaultGestures = true,
  });

  final ComicBase doc;

  final ContextMenu? contextMenu;

  final void Function(dynamic, ComicBase)? onItemSelected;

  final bool enableDefaultGestures;

  @override
  Widget build(BuildContext context) {
    final item = doc;

    return Stack(
      children: [
        Positioned.fill(
          child: contextMenu != null
              ? ContextMenuRegion(
                  contextMenu: contextMenu!,
                  enableDefaultGestures: enableDefaultGestures,
                  onItemSelected: (value) => onItemSelected?.call(value, item),
                  child: _buildContent(context, item),
                )
              : _buildContent(context, item),
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

  Widget _buildContent(BuildContext context, ComicBase item) {
    return InkWell(
      borderRadius: .circular(12),
      onTap: () {
        context.push('/details/${item.uid}');
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        child: SingleChildScrollView(
          child: Column(
            spacing: 3,
            children: [
              AspectRatio(
                aspectRatio: 1 / 1.4,
                child: UiImage(
                  url: doc.thumb.url,
                  cacheWidth: 140,
                  shape: .rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    );
  }
}
