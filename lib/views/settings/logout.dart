import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/router/app_router.dart';

class Logout extends StatefulWidget {
  const Logout({super.key});

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout),
      title: Text('退出登录'),
      trailing: Icon(Icons.chevron_right),
      onTap: () async {
        final bool? result = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('退出登录'),
              content: const Text('确定要退出登录吗？'),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => context.pop(false),
                ),
                TextButton(
                  child: const Text('确定'),
                  onPressed: () => context.pop(true),
                ),
              ],
            );
          },
        );
        if (result == true) {
          logout();
        }
      },
    );
  }
}
