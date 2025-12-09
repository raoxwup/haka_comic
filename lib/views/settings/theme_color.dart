import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/providers/theme_provider.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class ThemeColor extends StatelessWidget {
  const ThemeColor({super.key});

  static final List<String> _colors = [
    'System',
    'Red',
    'Pink',
    'Green',
    'Blue',
    'Yellow',
    'Orange',
    'Purple',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeState = ref.watch(themeProvider);
        return MenuListTile.withValue(
          title: '主题颜色',
          value: themeState.primaryColor,
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
                            colors: [
                              Colors.red,
                              Colors.pink,
                              Colors.green,
                              Colors.blue,
                              Colors.yellow,
                              Colors.orange,
                              Colors.purple,
                            ],
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
                          color: ThemeNotifier.stringToColor(color),
                          shape: BoxShape.circle,
                        ),
                      ),
                title: Text(color),
              ),
            );
          }).toList(),
          onSelected: (value) =>
              ref.read(themeProvider.notifier).setPrimaryColor(value),
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
