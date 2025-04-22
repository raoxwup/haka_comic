import 'package:flutter/material.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

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

  ThemeProvider() {
    final mode =
        SharedPreferencesUtil.prefs.getString('theme_mode') ?? 'System';
    _themeMode = stringToThemeMode[mode]!;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    SharedPreferencesUtil.prefs.setString(
      'theme_mode',
      themeModeToString[mode]!,
    );
    notifyListeners();
  }
}
