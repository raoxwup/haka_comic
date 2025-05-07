import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/change_password.dart';
import 'package:haka_comic/views/settings/clear_cache.dart';
import 'package:haka_comic/views/settings/logout.dart';
import 'package:haka_comic/views/settings/theme.dart' as t;

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
          Block(title: '外观', children: [const t.Theme()]),
          const SizedBox(height: 20),
          Block(title: '哔咔相关', children: [const ChangePassword()]),
          const SizedBox(height: 20),
          Block(title: '通用', children: [const ClearCache()]),
          const SizedBox(height: 20),
          Block(children: [const Logout()]),
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
              alpha: 0.65,
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
