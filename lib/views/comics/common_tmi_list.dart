import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/views/comics/simple_list_item.dart';
import 'package:haka_comic/views/comics/tmi_list.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';

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
  });

  final List<ComicBase> comics;

  final Widget Function(BuildContext)? pageSelectorBuilder;

  final Widget Function(BuildContext)? footerBuilder;

  final ScrollController? controller;

  final ContextMenu? contextMenu;

  final void Function(dynamic, ComicBase)? onItemSelected;

  final bool enableDefaultGestures;

  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  @override
  Widget build(BuildContext context) {
    return TMIList(
      controller: controller,
      itemCount: comics.length,
      pageSelectorBuilder: pageSelectorBuilder,
      footerBuilder: footerBuilder,
      itemBuilder: (context, index) {
        final item = comics[index];
        final key = ValueKey(item.uid);
        return isSimpleMode
            ? SimpleListItem(
                doc: item,
                key: key,
                onItemSelected: onItemSelected,
                enableDefaultGestures: enableDefaultGestures,
                contextMenu: contextMenu,
              )
            : ListItem(
                doc: item,
                key: key,
                onItemSelected: onItemSelected,
                enableDefaultGestures: enableDefaultGestures,
                contextMenu: contextMenu,
              );
      },
    );
  }
}
