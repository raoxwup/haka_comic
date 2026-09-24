import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';

class ApiSettings extends StatefulWidget {
  const ApiSettings({super.key});

  @override
  State<ApiSettings> createState() => _ApiSettingsState();
}

class _ApiSettingsState extends State<ApiSettings> {
  Api _api = AppConf().api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API切换')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          children: [
            Block(
              title: '服务器',
              children: [
                for (var api in Api.values)
                  _ApiTile(
                    api: api,
                    selected: _api == api,
                    onTap: () => _selectApi(api),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Block(title: '说明', children: [_ApiTip()]),
          ],
        ),
      ),
    );
  }

  void _selectApi(Api api) {
    setState(() {
      _api = api;
      AppConf().api = api;
      Client.setBaseUrl(api.host);
    });
  }
}

class _ApiTile extends StatelessWidget {
  const _ApiTile({
    required this.api,
    required this.selected,
    required this.onTap,
  });

  final Api api;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.14)
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          selected ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined,
          size: 22,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(api.name),
      subtitle: Text(_apiDescription(api)),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      selected: selected,
      selectedColor: colorScheme.primary,
      onTap: onTap,
    );
  }

  String _apiDescription(Api api) {
    return switch (api) {
      Api.picacomic => '官方直连，适合可直接访问官方接口的网络环境',
      Api.go2778 => 'CDN中转，通常国内网络可直接访问，但速度较慢',
    };
  }
}

class _ApiTip extends StatelessWidget {
  const _ApiTip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Text(
        '如果当前服务器无法加载内容，可以切换到另一个 API 后重试。'
        '有条件时推荐使用「${Api.picacomic.name}」，'
        '国内网络通常可以优先尝试「${Api.go2778.name}」。',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    );
  }
}
