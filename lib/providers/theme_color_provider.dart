import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:provider/provider.dart';

enum ThemeColorOption {
  system(Colors.white, 'System'),
  red(Colors.red, 'Red'),
  pink(Colors.pink, 'Pink'),
  green(Colors.green, 'Green'),
  blue(Colors.blue, 'Blue'),
  yellow(Colors.yellow, 'Yellow'),
  orange(Colors.orange, 'Orange'),
  purple(Colors.purple, 'Purple');

  final Color color;
  final String title;
  const ThemeColorOption(this.color, this.title);

  static ThemeColorOption fromTitle(String title) {
    return ThemeColorOption.values.firstWhere(
      (x) => x.title == title,
      orElse: () => ThemeColorOption.system,
    );
  }
}

extension BuildContextThemeColorExt on BuildContext {
  ThemeColorProvider get themeColorReader => read<ThemeColorProvider>();
  ThemeColorProvider get themeColorWatcher => watch<ThemeColorProvider>();
  T themeColorSelector<T>(T Function(ThemeColorProvider) s) =>
      select<ThemeColorProvider, T>(s);
}

class ThemeColorProvider extends ChangeNotifier {
  ThemeColorOption _themeColor = ThemeColorOption.fromTitle(
    AppConf().primaryColor,
  );

  ThemeColorOption get themeColor => _themeColor;

  set themeColor(ThemeColorOption value) {
    _themeColor = value;
    AppConf().primaryColor = value.title;
    notifyListeners();
  }
}
