import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';

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

  void _showNormalizationSelector(AppConf conf) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('规范化搜索词'),
          children: _normalizationOptions.map((opt) {
            final selected = conf.searchNormalization == opt.$1;
            return SimpleDialogOption(
              onPressed: () {
                setState(() => conf.searchNormalization = opt.$1);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(opt.$2),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conf = AppConf();

    return Column(
      children: [
        // ═══ 规范化搜索词 ═══
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.translate_outlined, size: 22),
          ),
          title: const Text('规范化搜索词'),
          subtitle: const Text('将搜索词统一转换后再查询'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Text(
                _normalizationOptions
                    .firstWhere((o) => o.$1 == conf.searchNormalization)
                    .$2,
                style: const TextStyle(fontSize: 12),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _showNormalizationSelector(conf),
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
