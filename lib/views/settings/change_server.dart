import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';

class ChangeServer extends StatefulWidget {
  const ChangeServer({super.key});

  @override
  State<ChangeServer> createState() => _ChangeServerState();
}

class _ChangeServerState extends State<ChangeServer> {
  Server _server = AppConf().server;

  void _showServerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择分流服务器'),
          children:
              Server.values.map((server) {
                return SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      _server = server;
                      AppConf().server = server;
                    });
                    context.pop();
                  },
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      title: const Text('切换分流'),
      trailing: Row(
        spacing: 5.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getServerDisplayName(_server),
            style: const TextStyle(fontSize: 12),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: _showServerDialog,
    );
  }
}
