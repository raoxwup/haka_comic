import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _primaryColor = 'System';

  ThemeMode get themeMode => _themeMode;

  String get primaryColor => _primaryColor;

  static const Map<String, ThemeMode> stringToThemeMode = {
    'System': ThemeMode.system,
    'Light': ThemeMode.light,
    'Dark': ThemeMode.dark,
  };

  static const Map<ThemeMode, String> themeModeToString = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  static Color stringToColor(String color) {
    return switch (color) {
      'Red' => Colors.red,
      'Pink' => Colors.pink,
      'Green' => Colors.green,
      'Blue' => Colors.blue,
      'Yellow' => Colors.yellow,
      'Orange' => Colors.orange,
      'Purple' => Colors.purple,
      _ => Colors.blue,
    };
  }

  ThemeProvider() {
    final mode = AppConf().themeMode;
    _themeMode = stringToThemeMode[mode]!;
    _primaryColor = AppConf().primaryColor;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    AppConf().themeMode = themeModeToString[mode]!;
    notifyListeners();
  }

  void setPrimaryColor(String color) {
    _primaryColor = color;
    AppConf().primaryColor = color;
    notifyListeners();
  }
}
