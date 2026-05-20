import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';

class SearchSettings extends StatefulWidget {
  const SearchSettings({super.key});

  @override
  State<SearchSettings> createState() => _SearchSettingsState();
}

class _SearchSettingsState extends State<SearchSettings> {
  static const _scopeOptions = [
    ('title', '标题'),
    ('tag', 'Tag'),
    ('category', '分类'),
    ('author', '作者'),
  ];

  static const _normalizationOptions = [
    ('off', '关'),
    ('s2t', '简→繁'),
    ('t2s', '繁→简'),
  ];

  String _scopeLabel(AppConf conf) {
    final validCount = conf.searchScopes
        .where((s) => _scopeOptions.any((o) => o.$1 == s))
        .length;
    if (validCount == 0) return '未选择';
    return '已选 $validCount 项';
  }

  String _scopeSubtitle(AppConf conf) {
    if (conf.searchScopes.isEmpty) return '点击选择搜索范围';
    return _scopeOptions
        .where((o) => conf.searchScopes.contains(o.$1))
        .map((o) => o.$2)
        .join('、');
  }

  void _showScopeSelector(AppConf conf) {
    showDialog(
      context: context,
      builder: (ctx) {
        final tempScopes = List<String>.from(conf.searchScopes);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('搜索范围'),
              contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._scopeOptions.map((opt) {
                    return CheckboxListTile(
                      value: tempScopes.contains(opt.$1),
                      title: Text(opt.$2),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            tempScopes.add(opt.$1);
                          } else {
                            tempScopes.remove(opt.$1);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() => conf.searchScopes = tempScopes);
                    Navigator.pop(ctx);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

        // ═══ 搜索范围（仅条件搜索开启时显示）═══
        if (conf.enableBooleanSearch)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.filter_list_outlined, size: 22),
            ),
            title: const Text('搜索范围'),
            subtitle: Text(
              _scopeSubtitle(conf),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                Flexible(
                  child: Text(
                    _scopeLabel(conf),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showScopeSelector(conf),
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
