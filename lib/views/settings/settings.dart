import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/clear_cache.dart';
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
        padding: const EdgeInsets.all(12),
        children: [
          Block(
            title: '外观',
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
                            Text(
                              '选择主题模式',
                              style: context.textTheme.titleMedium,
                            ),
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
            ],
          ),
          SizedBox(height: 20),
          Block(
            title: '哔咔相关',
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('修改密码'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 20),
          Block(title: '通用', children: [const ClearCache()]),
          SizedBox(height: 20),
          Block(
            children: [
              ListTile(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Block extends StatelessWidget {
  const Block({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
            child: Text(
              title!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: context.colorScheme.secondaryContainer.withValues(
              alpha: 0.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ],
    );
  }
}
