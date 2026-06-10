import 'package:flutter/material.dart';
import 'package:haka_comic/utils/app_icon.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class AppIcon extends StatefulWidget {
  const AppIcon({super.key});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  String _icon = 'default';

  static const _titles = {'default': '经典', 'old': '现代'};

  @override
  void initState() {
    super.initState();
    AppIconChannel.getIcon().then((value) {
      if (mounted) {
        setState(() => _icon = value);
      }
    });
  }

  Future<void> _select(String name) async {
    if (name == _icon) return;
    await AppIconChannel.setIcon(name);
    if (mounted) {
      setState(() => _icon = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withAction(
      icon: Icons.apps_outlined,
      title: '应用图标',
      value: _titles[_icon],
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 400),
          isScrollControlled: true,
          builder: (sheetContext) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 36,
                    decoration: BoxDecoration(
                      color: context.colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('选择应用图标', style: context.textTheme.titleMedium),
                  Text(
                    '切换后启动器可能短暂闪烁，桌面已固定的快捷方式可能失效',
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  RadioGroup<String>(
                    groupValue: _icon,
                    onChanged: (value) async {
                      Navigator.of(sheetContext).pop();
                      if (value != null) {
                        await _select(value);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _titles.entries
                          .map(
                            (entry) => RadioListTile<String>(
                              title: Text(entry.value),
                              value: entry.key,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
