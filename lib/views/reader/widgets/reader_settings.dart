import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';

class ReaderSettings extends StatefulWidget {
  const ReaderSettings({super.key});

  @override
  State<ReaderSettings> createState() => _ReaderSettingsState();
}

class _ReaderSettingsState extends State<ReaderSettings> {
  final slipFactor = ValueNotifier(AppConf().slipFactor);
  final enableGesture = ValueNotifier(AppConf().enableGesture);
  final enablePageAnimation = ValueNotifier(AppConf().enablePageAnimation);

  @override
  Widget build(BuildContext context) {
    final showPageNumbers = context.stateSelector((p) => p.showPageNumbers);
    final widthRatio = context.stateSelector((p) => p.verticalListWidthRatio);

    return Scaffold(
      appBar: AppBar(title: const Text('阅读设置')),
      body: ListView(
        children: [
          SwitchListTile(
            value: showPageNumbers,
            onChanged: (v) {
              context.stateReader.toggleShowPageNumbers();
            },
            title: const Text('显示页码'),
          ),
          ValueListenableBuilder(
            valueListenable: slipFactor,
            builder: (context, value, child) {
              return ListTile(
                title: const Text('滑动距离'),
                trailing: Text('$value * 屏高'),
                subtitle: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    const Text('用于调整阅读时翻页的滑动距离。仅在“连续从上到下”阅读模式下生效。'),
                    Slider(
                      padding: const .symmetric(horizontal: 0.0),
                      value: value * 10,
                      min: 3,
                      max: 10,
                      divisions: 7,
                      onChanged: (value) {
                        slipFactor.value = value / 10;
                        AppConf().slipFactor = value / 10;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: const Text('漫画宽度'),
            trailing: Text('$widthRatio * 屏宽'),
            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                const Text(
                  '用于调整阅读时漫画的宽度，对于大屏阅读韩漫等类似漫画时可能有帮助。仅在“连续从上到下”阅读模式下生效。',
                ),
                Slider(
                  padding: const .symmetric(horizontal: 0.0),
                  value: widthRatio * 10,
                  min: 2,
                  max: 10,
                  divisions: 8,
                  onChanged: (double v) {
                    context.stateReader.verticalListWidthRatio = v / 10;
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: enableGesture,
            builder: (context, value, child) {
              return SwitchListTile(
                value: value,
                onChanged: (value) {
                  AppConf().enableGesture = value;
                  enableGesture.value = value;
                },
                title: const Text('点击翻页'),
                subtitle: const Text('启用时，点击屏幕特定区域可以翻页。'),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: enablePageAnimation,
            builder: (context, value, child) {
              return SwitchListTile(
                value: value,
                onChanged: (value) {
                  AppConf().enablePageAnimation = value;
                  enablePageAnimation.value = value;
                },
                title: const Text('翻页动画'),
                subtitle: const Text('关闭后，点击翻页时不会有过渡动画。有助于改善墨水屏设备的阅读体验。'),
              );
            },
          ),
        ],
      ),
    );
  }
}
