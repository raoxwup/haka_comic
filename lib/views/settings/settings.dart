import 'package:flutter/material.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/theme_icon.dart';
import 'package:haka_comic/views/settings/theme_switch.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.contrast),
            title: Text('主题模式'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                useSafeArea: true,
                constraints: BoxConstraints(maxWidth: 400),
                isScrollControlled: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ThemeIcon(),
                        SizedBox(height: 20),
                        Text('选择主题模式', style: context.textTheme.titleMedium),
                        Text(
                          '选择System，亮暗模式会随着系统模式的变化而变化',
                          style: context.textTheme.bodySmall,
                        ),
                        SizedBox(height: 20),
                        ThemeSwitch(),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          TextButton(
            onPressed: () {
              logout();
            },
            child: Text('退出登录'),
          ),
        ],
      ),
    );
  }
}
