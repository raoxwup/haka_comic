import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class Pager extends StatefulWidget {
  const Pager({super.key});

  @override
  State<Pager> createState() => _PagerState();
}

class _PagerState extends State<Pager> {
  bool _pagination = AppConf().pagination;
  final maps = {'分页': true, '连续': false};

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withValue(
      icon: Icons.unfold_more_outlined,
      title: '分页模式',
      value: _pagination ? '分页' : '连续',
      items:
          maps.entries.map((entry) {
            return PopupMenuItem(
              value: entry.value,
              child: ListTile(
                leading: Icon(
                  _pagination == entry.value
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(entry.key),
              ),
            );
          }).toList(),
      onSelected: (value) {
        setState(() {
          _pagination = value;
          AppConf().pagination = value;
        });
      },
    );
  }
}
