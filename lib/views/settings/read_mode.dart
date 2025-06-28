import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class ReadModeChanger extends StatefulWidget {
  const ReadModeChanger({super.key});

  @override
  State<ReadModeChanger> createState() => _ReadModeChangerState();
}

class _ReadModeChangerState extends State<ReadModeChanger> {
  ReadMode _readMode = AppConf().readMode;

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withValue(
      icon: Icons.chrome_reader_mode_outlined,
      title: '阅读模式',
      value: readModeToString(_readMode),
      items:
          ReadMode.values.map((mode) {
            return PopupMenuItem(
              value: mode,
              child: ListTile(
                leading: Icon(
                  _readMode == mode
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(readModeToString(mode)),
              ),
            );
          }).toList(),
      onSelected: (value) {
        setState(() {
          _readMode = value;
          AppConf().readMode = value;
        });
      },
    );
  }
}
