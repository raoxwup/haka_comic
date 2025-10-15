import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/views/settings/change_image_quality.dart';
import 'package:haka_comic/views/settings/change_password.dart';
import 'package:haka_comic/views/settings/clear_cache.dart';
import 'package:haka_comic/views/settings/comic_block_scale.dart';
import 'package:haka_comic/views/settings/logout.dart';
import 'package:haka_comic/views/settings/network.dart';
import 'package:haka_comic/views/settings/pager.dart';
import 'package:haka_comic/views/settings/read_mode.dart';
import 'package:haka_comic/views/settings/slip_factor.dart';
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
              const Network(),
              MenuListTile.withAction(
                icon: Icons.texture_outlined,
                title: '屏蔽',
                onTap: () => context.push('/blacklist'),
              ),
              MenuListTile.withAction(
                icon: Icons.topic_outlined,
                title: '显示的分类',
                onTap: () => context.push('/visible_categories'),
              ),
              MenuListTile.withAction(
                icon: Icons.label_off_outlined,
                title: 'Tag屏蔽',
                onTap: () => context.push('/tag_block'),
              ),
              MenuListTile.withAction(
                icon: Icons.spellcheck_outlined,
                title: '标题关键词屏蔽',
                onTap: () => context.push('/word_block'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Block(
            title: '浏览',
            children: [BrowseMode(), Pager(), ComicBlockScale()],
          ),
          const SizedBox(height: 20),
          const Block(title: '阅读', children: [ReadModeChanger(), SlipFactor()]),
          const SizedBox(height: 20),
          Block(
            title: '备份',
            children: [
              MenuListTile.withAction(
                icon: Icons.backup_outlined,
                title: 'WebDAV',
                onTap: () {
                  context.push('/webdav');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Block(
            title: '通用',
            children: [
              const ClearCache(),
              MenuListTile.withAction(
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
