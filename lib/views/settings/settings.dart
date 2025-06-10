import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/change_image_quality.dart';
import 'package:haka_comic/views/settings/change_password.dart';
import 'package:haka_comic/views/settings/change_server.dart';
import 'package:haka_comic/views/settings/clear_cache.dart';
import 'package:haka_comic/views/settings/logout.dart';
import 'package:haka_comic/views/settings/theme.dart' as t;
import 'package:haka_comic/views/settings/theme_color.dart';

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
          const Block(title: '外观', children: [t.Theme(), ThemeColor()]),
          const SizedBox(height: 20),
          Block(
            title: '哔咔相关',
            children: [
              const ChangePassword(),
              const ChangeImageQuality(),
              const ChangeServer(),
              ListTile(
                leading: const Icon(Icons.texture_outlined),
                title: const Text('屏蔽'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/blacklist');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Block(
            title: '通用',
            children: [
              const ClearCache(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/about');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Block(children: [Logout()]),
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
              alpha: 0.45,
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
