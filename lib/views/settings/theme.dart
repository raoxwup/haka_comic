import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/providers/theme_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/theme_icon.dart';
import 'package:haka_comic/views/settings/theme_switch.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class Theme extends ConsumerWidget {
  const Theme({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(
      themeProvider.select((x) => x.themeMode),
    );
    return MenuListTile.withAction(
      icon: Icons.contrast_outlined,
      title: '主题模式',
      value: ThemeNotifier.themeModeToString[themeMode] ?? 'System',
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 400),
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ThemeIcon(),
                  const SizedBox(height: 20),
                  Text('选择主题模式', style: context.textTheme.titleMedium),
                  Text(
                    '选择System，亮暗模式会随着系统模式的变化而变化',
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  const ThemeSwitch(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
