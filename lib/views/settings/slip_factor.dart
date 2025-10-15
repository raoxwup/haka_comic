import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class SlipFactor extends StatefulWidget {
  const SlipFactor({super.key});

  @override
  State<SlipFactor> createState() => _SlipFactorState();
}

class _SlipFactorState extends State<SlipFactor> {
  final _slipFactor = ValueNotifier(AppConf().slipFactor);

  void _handleTap() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(20),
          title: const Text('滑动距离'),
          children: [
            const Text('此项设置仅当阅读模式为“连续从上到下”时生效，用于调整阅读时翻页的滑动距离。'),
            ValueListenableBuilder<double>(
              valueListenable: _slipFactor,
              builder: (context, value, child) {
                return Slider(
                  value: value * 10,
                  min: 3,
                  max: 10,
                  divisions: 7,
                  label: '$value * 屏高',
                  onChanged: (double value) {
                    _slipFactor.value = value / 10;
                    AppConf().slipFactor = value / 10;
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _slipFactor,
      builder: (context, value, child) {
        return MenuListTile.withAction(
          title: '滑动距离',
          value: '$value * 屏高',
          icon: Icons.straighten_outlined,
          onTap: _handleTap,
        );
      },
    );
  }
}
