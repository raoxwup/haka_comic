import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class SearchSettings extends StatefulWidget {
  const SearchSettings({super.key});

  @override
  State<SearchSettings> createState() => _SearchSettingsState();
}

class _SearchSettingsState extends State<SearchSettings> {
  static const _normalizationOptions = [
    ('off', '关'),
    ('s2t', '简→繁'),
    ('t2s', '繁→简'),
  ];

  @override
  Widget build(BuildContext context) {
    final conf = AppConf();

    return Column(
      children: [
        // ═══ 规范化搜索词 ═══
        MenuListTile.withValue(
          icon: Icons.translate_outlined,
          title: '规范化搜索词',
          subtitle: const Text('将搜索词统一转换后再查询'),
          value: _normalizationOptions
              .firstWhere((o) => o.$1 == conf.searchNormalization)
              .$2,
          items: _normalizationOptions.map((opt) {
            final selected = conf.searchNormalization == opt.$1;
            return PopupMenuItem(
              value: opt.$1,
              child: ListTile(
                leading: Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(opt.$2),
              ),
            );
          }).toList(),
          onSelected: (value) {
            setState(() => conf.searchNormalization = value);
          },
        ),

        // ═══ 条件搜索 ═══
        SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.query_builder_outlined, size: 22),
          ),
          title: const Text('条件搜索'),
          subtitle: const Text('空格=OR、+=AND、-=NOT'),
          value: conf.enableBooleanSearch,
          onChanged: (value) {
            setState(() => conf.enableBooleanSearch = value);
          },
        ),

        // ═══ 每秒请求数上限（仅条件搜索开启时显示）═══
        if (conf.enableBooleanSearch)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speed_outlined, size: 22),
            ),
            title: const Text('每秒请求数上限'),
            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        value: conf.maxRequestsPerSecond.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '${conf.maxRequestsPerSecond}',
                        onChanged: (value) {
                          setState(
                            () => conf.maxRequestsPerSecond = value.round(),
                          );
                        },
                      ),
                    ),
                    Text(
                      '${conf.maxRequestsPerSecond} 次/秒',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '布尔搜索结果不足时，自动请求后续页补充的速率上限',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
