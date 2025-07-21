import 'package:flutter/material.dart';
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
    this.isSelected = false,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.onSecondaryTap,
    this.pageSelectorBuilder,
    this.controller,
  });

  final List<Doc> comics;

  final bool isSelected;

  final void Function(TapDownDetails)? onTapDown;

  final void Function(TapDownDetails)? onSecondaryTapDown;

  final void Function(Doc)? onLongPress;

  final void Function()? onSecondaryTap;

  final Widget Function(BuildContext)? pageSelectorBuilder;

  final ScrollController? controller;

  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  @override
  Widget build(BuildContext context) {
    return TMIList(
      controller: controller,
      itemCount: comics.length,
      pageSelectorBuilder: pageSelectorBuilder,
      itemBuilder: (context, index) {
        final item = comics[index];
        final key = ValueKey(item.uid);
        return isSimpleMode
            ? SimpleListItem(
              doc: item,
              key: key,
              isSelected: isSelected,
              onTapDown: onTapDown,
              onSecondaryTapDown: onSecondaryTapDown,
              onLongPress: onLongPress,
              onSecondaryTap: onSecondaryTap,
            )
            : ListItem(
              doc: item,
              key: key,
              isSelected: isSelected,
              onTapDown: onTapDown,
              onSecondaryTapDown: onSecondaryTapDown,
              onLongPress: onLongPress,
              onSecondaryTap: onSecondaryTap,
            );
      },
    );
  }
}
