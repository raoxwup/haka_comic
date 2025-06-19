import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class ChangeServer extends StatefulWidget {
  const ChangeServer({super.key});

  @override
  State<ChangeServer> createState() => _ChangeServerState();
}

class _ChangeServerState extends State<ChangeServer> {
  Server _server = AppConf().server;

  @override
  Widget build(BuildContext context) {
    return MenuListTile(
      icon: Icons.swap_horiz_outlined,
      title: '切换分流',
      value: getServerDisplayName(_server),
      items:
          Server.values.map((server) {
            return PopupMenuItem(
              value: server,
              child: ListTile(
                leading: Icon(
                  _server == server
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(getServerDisplayName(server)),
              ),
            );
          }).toList(),
      onSelected:
          (value) => setState(() {
            _server = value;
            AppConf().server = value;
          }),
    );
  }
}
