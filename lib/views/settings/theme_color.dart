import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/providers/theme_provider.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class ThemeColor extends StatelessWidget {
  const ThemeColor({super.key});

  static final List<String> _colors = [
    ...ThemeColorOption.values.map((e) => e.title),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeColor = ref.watch(themeColorProvider);
        return MenuListTile.withValue(
          title: '主题颜色',
          value: themeColor.title,
          icon: Icons.color_lens_outlined,
          items: _colors.map((String color) {
            return PopupMenuItem(
              value: color,
              child: ListTile(
                leading: color == 'System'
                    ? Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: SweepGradient(
                            colors: ThemeColorOption.values
                                .where((element) => element.title != 'System')
                                .map((e) => e.color)
                                .toList(),
                            stops: _generateStops(7),
                            center: Alignment.center,
                            startAngle: 0,
                            endAngle: 2 * pi,
                            tileMode: TileMode.clamp,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.settings,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ThemeColorOption.fromTitle(color).color,
                          shape: BoxShape.circle,
                        ),
                      ),
                title: Text(color),
              ),
            );
          }).toList(),
          onSelected: (value) => ref
              .read(themeColorProvider.notifier)
              .updateThemeColor(ThemeColorOption.fromTitle(value)),
        );
      },
    );
  }

  List<double> _generateStops(int count) {
    final stops = <double>[];
    for (int i = 0; i < count; i++) {
      stops.add(i / (count - 1));
    }
    return stops;
  }
}
