import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

enum ComicBlockMode { simple, detailed }

String comicBlockModeToString(ComicBlockMode mode) {
  return switch (mode) {
    ComicBlockMode.simple => '简洁',
    ComicBlockMode.detailed => '详细',
  };
}

ComicBlockMode stringToComicBlockMode(String mode) {
  return switch (mode) {
    '简洁' => ComicBlockMode.simple,
    '详细' => ComicBlockMode.detailed,
    _ => ComicBlockMode.detailed,
  };
}

class BrowseMode extends StatefulWidget {
  const BrowseMode({super.key});

  @override
  State<BrowseMode> createState() => _BrowseModeState();
}

class _BrowseModeState extends State<BrowseMode> {
  ComicBlockMode _mode = AppConf().comicBlockMode;

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withValue(
      icon: Icons.view_day_outlined,
      title: '漫画块',
      value: comicBlockModeToString(_mode),
      items:
          ComicBlockMode.values.map((mode) {
            return PopupMenuItem(
              value: mode,
              child: ListTile(
                leading: Icon(
                  _mode == mode
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(comicBlockModeToString(mode)),
              ),
            );
          }).toList(),
      onSelected: (value) {
        setState(() {
          _mode = value;
          AppConf().comicBlockMode = value;
        });
      },
    );
  }
}
