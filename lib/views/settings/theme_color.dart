import 'dart:math';

import 'package:flutter/material.dart';
import 'package:haka_comic/model/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeColor extends StatefulWidget {
  const ThemeColor({super.key});

  @override
  State<ThemeColor> createState() => _ThemeColorState();
}

class _ThemeColorState extends State<ThemeColor> {
  final MenuController _menuController = MenuController();
  final List<String> _colors = [
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
    final color = context.select<ThemeProvider, String>(
      (values) => values.primaryColor,
    );

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(20, 0),
      menuChildren: [
        ..._colors.map((String color) {
          return MenuItemButton(
            onPressed: () {
              context.read<ThemeProvider>().setPrimaryColor(color);
              _menuController.close();
            },
            child: Row(
              spacing: 8.0,
              children: [
                color == 'System'
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
                    )
                    : CircleAvatar(
                      backgroundColor: ThemeProvider.stringToColor(color),
                      radius: 10,
                    ),
                Text(color),
              ],
            ),
          );
        }),
      ],
      child: ListTile(
        title: const Text('主题颜色'),
        leading: const Icon(Icons.color_lens_outlined),
        trailing: Row(
          spacing: 5.0,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(color, style: const TextStyle(fontSize: 12)),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
          }
        },
      ),
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
