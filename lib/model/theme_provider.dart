import 'package:flutter/material.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color? _primaryColor;

  ThemeMode get themeMode => _themeMode;

  Color? get primaryColor => _primaryColor;

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

    final argb32 = SharedPreferencesUtil.prefs.getInt('primary_color');
    _primaryColor = argb32 != null ? Color(argb32) : null;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    SharedPreferencesUtil.prefs.setString(
      'theme_mode',
      themeModeToString[mode]!,
    );
    notifyListeners();
  }

  void setPrimaryColor(Color? color) {
    _primaryColor = color;
    if (color != null) {
      SharedPreferencesUtil.prefs.setInt('primary_color', color.toARGB32());
    } else {
      SharedPreferencesUtil.prefs.remove('primary_color');
    }
    notifyListeners();
  }
}
