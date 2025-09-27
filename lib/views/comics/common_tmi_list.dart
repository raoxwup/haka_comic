import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/views/comics/simple_list_item.dart';
import 'package:haka_comic/views/comics/tmi_list.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';

class CommonTMIList extends StatelessWidget {
  const CommonTMIList({
    super.key,
    required this.comics,
    required this.blockedTags,
    required this.blockedWords,
    this.isSelected = false,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.onSecondaryTap,
    this.pageSelectorBuilder,
    this.controller,
    this.footerBuilder,
  });

  final List<Doc> comics;

  final bool isSelected;

  final void Function(TapDownDetails)? onTapDown;

  final void Function(TapDownDetails)? onSecondaryTapDown;

  final void Function(Doc)? onLongPress;

  final void Function()? onSecondaryTap;

  final Widget Function(BuildContext)? pageSelectorBuilder;

  final Widget Function(BuildContext)? footerBuilder;

  final ScrollController? controller;

  final List<String> blockedTags;

  final List<String> blockedWords;

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
        // 屏蔽的tag
        final tag = item.tags.firstWhereOrNull(
          (item) => blockedTags.contains(item),
        );
        // 屏蔽的分类
        final category = item.categories.firstWhereOrNull(
          (item) => AppConf().blacklist.contains(item),
        );
        // 屏蔽的标题关键词
        final word = blockedWords.firstWhereOrNull(
          (word) => item.title.contains(word),
        );
        return isSimpleMode
            ? SimpleListItem(
              doc: item,
              key: key,
              isSelected: isSelected,
              onTapDown: onTapDown,
              onSecondaryTapDown: onSecondaryTapDown,
              onLongPress: onLongPress,
              onSecondaryTap: onSecondaryTap,
              blockedWords: category ?? tag ?? word,
            )
            : ListItem(
              doc: item,
              key: key,
              isSelected: isSelected,
              onTapDown: onTapDown,
              onSecondaryTapDown: onSecondaryTapDown,
              onLongPress: onLongPress,
              onSecondaryTap: onSecondaryTap,
              blockedWords: category ?? tag ?? word,
            );
      },
    );
  }
}
