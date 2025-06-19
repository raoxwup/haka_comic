import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/views/settings/change_image_quality.dart';
import 'package:haka_comic/views/settings/change_password.dart';
import 'package:haka_comic/views/settings/change_server.dart';
import 'package:haka_comic/views/settings/clear_cache.dart';
import 'package:haka_comic/views/settings/logout.dart';
import 'package:haka_comic/views/settings/theme.dart' as t;
import 'package:haka_comic/views/settings/theme_color.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

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
              MenuListTile(
                icon: Icons.texture_outlined,
                title: '屏蔽',
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
              MenuListTile(
                icon: Icons.info_outline,
                title: '关于',
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
