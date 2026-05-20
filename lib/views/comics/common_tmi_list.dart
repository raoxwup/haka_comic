import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/views/comics/simple_list_item.dart';
import 'package:haka_comic/views/comics/tmi_list.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/widgets/empty.dart';

class CommonTMIList extends StatelessWidget {
  const CommonTMIList({
    super.key,
    required this.comics,
    this.pageSelectorBuilder,
    this.controller,
    this.footerBuilder,
    this.contextMenu,
    this.onItemSelected,
    this.enableDefaultGestures = true,
    this.selectedCids,
    this.onItemLongPress,
    this.emptyRefreshCallback,
  });

  final List<ComicBase> comics;

  final Widget Function(BuildContext)? pageSelectorBuilder;

  final Widget Function(BuildContext)? footerBuilder;

  final ScrollController? controller;

  final ContextMenu? contextMenu;

  final void Function(dynamic, ComicBase)? onItemSelected;

  final bool enableDefaultGestures;

  final Set<String>? selectedCids;

  final void Function(ComicBase)? onItemLongPress;

  /// 列表为空时显示刷新按钮，为 null 则不显示
  final VoidCallback? emptyRefreshCallback;

  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  @override
  Widget build(BuildContext context) {
    if (comics.isEmpty && emptyRefreshCallback != null) {
      return Empty(onRefresh: emptyRefreshCallback);
    }
    return TMIList(
      controller: controller,
      itemCount: comics.length,
      pageSelectorBuilder: pageSelectorBuilder,
      footerBuilder: footerBuilder,
      itemBuilder: (context, index) {
        final item = comics[index];
        final key = ValueKey(item.uid);
        final isSelected = selectedCids?.contains(item.uid) ?? false;
        final isSelecting = selectedCids != null;
        final void Function(dynamic, ComicBase)? itemSelected = isSelecting
            ? (_, _) => onItemSelected?.call(null, item)
            : onItemSelected;

        Widget child = isSimpleMode
            ? SimpleListItem(
                doc: item,
                key: key,
                onItemSelected: itemSelected,
                enableDefaultGestures: onItemLongPress == null ? enableDefaultGestures : false,
                contextMenu: contextMenu,
                isSelected: isSelected,
                isSelecting: isSelecting,
              )
            : ListItem(
                doc: item,
                key: key,
                onItemSelected: itemSelected,
                enableDefaultGestures: onItemLongPress == null ? enableDefaultGestures : false,
                contextMenu: contextMenu,
                isSelected: isSelected,
                isSelecting: isSelecting,
              );

        if (onItemLongPress != null) {
          child = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () => onItemLongPress!(item),
            onSecondaryTapUp: contextMenu != null
                ? (details) => showContextMenu(
                      context,
                      contextMenu: contextMenu!.copyWith(
                        position: contextMenu!.position ?? details.globalPosition,
                      ),
                      onItemSelected: (value) => onItemSelected?.call(value, item),
                    )
                : null,
            child: child,
          );
        }

        return child;
      },
    );
  }
}
