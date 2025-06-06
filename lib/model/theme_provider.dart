import 'package:flutter/material.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

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
    final mode =
        SharedPreferencesUtil.prefs.getString('theme_mode') ?? 'System';
    _themeMode = stringToThemeMode[mode]!;

    _primaryColor =
        SharedPreferencesUtil.prefs.getString('primary_color') ?? 'System';
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    SharedPreferencesUtil.prefs.setString(
      'theme_mode',
      themeModeToString[mode]!,
    );
    notifyListeners();
  }

  void setPrimaryColor(String color) {
    _primaryColor = color;
    SharedPreferencesUtil.prefs.setString('primary_color', color);
    notifyListeners();
  }
}
