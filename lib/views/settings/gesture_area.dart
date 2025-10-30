import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class GestureArea extends StatelessWidget {
  const GestureArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手势区域')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Block(
            children: [
              MenuListTile.withAction(
                title: '条漫模式',
                onTap: () => context.push(
                  '/gesture_area/details/${GestureAreaType.vertical.name}',
                ),
              ),
              MenuListTile.withAction(
                title: '页漫模式',
                onTap: () => context.push(
                  '/gesture_area/details/${GestureAreaType.horizontal.name}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum GestureAreaType {
  vertical,
  horizontal;

  static GestureAreaType fromName(String? name) {
    return GestureAreaType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => GestureAreaType.vertical,
    );
  }
}

class GestureAreaDetails extends StatefulWidget {
  const GestureAreaDetails({super.key, required this.type});

  final GestureAreaType type;

  @override
  State<GestureAreaDetails> createState() => _GestureAreaDetailsState();
}

class _GestureAreaDetailsState extends State<GestureAreaDetails> {
  late double factor = switch (widget.type) {
    GestureAreaType.vertical => AppConf().verticalCenterFraction * 10,
    GestureAreaType.horizontal => AppConf().horizontalCenterFraction * 10,
  };

  @override
  Widget build(BuildContext context) {
    final remaining = 10 - factor;
    final topBottomRatio = remaining / 2;

    // ignore: non_constant_identifier_names
    final DirectionBox = switch (widget.type) {
      GestureAreaType.vertical => Column.new,
      GestureAreaType.horizontal => Row.new,
    };

    final title = switch (widget.type) {
      GestureAreaType.vertical => '条漫模式',
      GestureAreaType.horizontal => '页漫模式',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            '菜单呼出区域所占屏幕比例',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          Slider(
            min: 1,
            max: 8,
            divisions: 7,
            value: factor,
            label: (factor / 10).toString(),
            onChanged: (value) {
              setState(() {
                factor = value;
                switch (widget.type) {
                  case GestureAreaType.vertical:
                    AppConf().verticalCenterFraction = value / 10;
                    break;
                  case GestureAreaType.horizontal:
                    AppConf().horizontalCenterFraction = value / 10;
                    break;
                }
              });
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              height: 370,
              width: 200,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: DirectionBox(
                children: [
                  Expanded(
                    flex: (topBottomRatio * 100).round(),
                    child: Container(color: const Color(0xFFB8C5D6)),
                  ),
                  Expanded(
                    flex: (factor * 100).round(),
                    child: Container(color: const Color(0xFFE0E7EE)),
                  ),
                  Expanded(
                    flex: (topBottomRatio * 100).round(),
                    child: Container(color: const Color(0xFFB8C5D6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: const Color(0xFFB8C5D6),
                ),
              ),
              Text('上下翻页区域', style: context.textTheme.bodySmall),
              const SizedBox(width: 18),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: const Color(0xFFE0E7EE),
                ),
              ),
              Text('呼出菜单区域', style: context.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
