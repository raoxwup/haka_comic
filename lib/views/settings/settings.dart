import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' hide Block;
import 'package:haka_comic/views/settings/auth.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';
import 'package:haka_comic/views/settings/change_image_quality.dart';
import 'package:haka_comic/views/settings/change_password.dart';
import 'package:haka_comic/views/settings/clear_cache.dart';
import 'package:haka_comic/views/settings/comic_block_scale.dart';
import 'package:haka_comic/views/settings/logout.dart';
import 'package:haka_comic/views/settings/pager.dart';
import 'package:haka_comic/views/settings/theme.dart' as t;
import 'package:haka_comic/views/settings/theme_color.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const .fromLTRB(12, 0, 12, 20),
          children: [
            const Block(title: '外观', children: [t.Theme(), ThemeColor()]),
            const SizedBox(height: 20),
            Block(
              title: '哔咔相关',
              children: [
                const ChangePassword(),
                const ChangeImageQuality(),
                MenuListTile.withAction(
                  icon: Icons.network_check_outlined,
                  title: 'API切换',
                  onTap: () => context.push('/api_settings'),
                  subtitle: const Text('修改访问的服务器地址'),
                ),
                MenuListTile.withAction(
                  icon: Icons.topic_outlined,
                  title: '显示的分类',
                  onTap: () => context.push('/visible_categories'),
                  subtitle: const Text('可设置分类页显示哪些分类'),
                ),
                MenuListTile.withAction(
                  icon: Icons.label_off_outlined,
                  title: '屏蔽',
                  onTap: () => context.push('/block_settings'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Block(
              title: '代理',
              children: [
                MenuListTile.withAction(
                  icon: Icons.hub_outlined,
                  title: 'SOCKS5代理',
                  onTap: () => context.push('/proxy_settings'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Block(
              title: '浏览',
              children: [BrowseMode(), Pager(), ComicBlockScale()],
            ),
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
                MenuListTile.withAction(
                  icon: Icons.sd_card_outlined,
                  title: '本地备份',
                  onTap: () {
                    context.push('/local_backup');
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
                  icon: Icons.folder_outlined,
                  title: '下载路径',
                  onTap: () {
                    context.push('/download_path');
                  },
                  subtitle: const Text('设置漫画下载保存目录'),
                ),
                const Auth(),
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
            Block(
              title: '调试',
              children: [
                MenuListTile.withAction(
                  icon: Icons.bug_report_outlined,
                  title: '日志',
                  onTap: () {
                    context.push('/logs');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Block(children: [Logout()]),
          ],
        ),
      ),
    );
  }
}
