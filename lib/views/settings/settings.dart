import 'package:flutter/material.dart';
import 'package:haka_comic/model/app_data.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/theme_icon.dart';
import 'package:provider/provider.dart';

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
            title: Text('颜色主题'),
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
                        Text('选择颜色模式', style: context.textTheme.titleMedium),
                        Text(
                          '选择跟随系统，亮暗模式会随着系统的变化而变化',
                          style: context.textTheme.bodySmall,
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        context
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {},
                                          child: Text(
                                            'System',
                                            style:
                                                context.textTheme.titleMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {},
                                          child: Text(
                                            'Light',
                                            style:
                                                context.textTheme.titleMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {},
                                          child: Text(
                                            'Dark',
                                            style:
                                                context.textTheme.titleMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: context.width / 3,
                                child: Container(
                                  margin: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // ListTile(
                        //   leading: Icon(Icons.light_mode),
                        //   title: Text('浅色主题'),
                        //   onTap: () {
                        //     context.read<AppData>().setThemeMode(
                        //       ThemeMode.light,
                        //     );
                        //   },
                        // ),
                        // ListTile(
                        //   leading: Icon(Icons.dark_mode),
                        //   title: Text('深色主题'),
                        //   onTap: () {
                        //     context.read<AppData>().setThemeMode(
                        //       ThemeMode.dark,
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
