import 'package:flutter/material.dart';
import 'package:haka_comic/model/theme_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/theme_icon.dart';
import 'package:haka_comic/views/settings/theme_switch.dart';
import 'package:provider/provider.dart';

class Theme extends StatefulWidget {
  const Theme({super.key});

  @override
  State<Theme> createState() => _ThemeState();
}

class _ThemeState extends State<Theme> {
  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = context.select<ThemeProvider, ThemeMode>(
      (data) => data.themeMode,
    );
    return ListTile(
      leading: Icon(Icons.contrast),
      title: Text('主题模式'),
      trailing: Row(
        spacing: 5.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ThemeProvider.themeModeToString[themeMode] ?? 'System',
            style: const TextStyle(fontSize: 12),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
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
    );
  }
}
