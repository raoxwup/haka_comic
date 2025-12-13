import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:provider/provider.dart';

enum ThemeModeOption {
  system(ThemeMode.system, 'System'),
  light(ThemeMode.light, 'Light'),
  dark(ThemeMode.dark, 'Dark');

  final ThemeMode mode;
  final String title;

  const ThemeModeOption(this.mode, this.title);

  static ThemeModeOption fromTitle(String title) {
    return ThemeModeOption.values.firstWhere(
      (x) => x.title == title,
      orElse: () => ThemeModeOption.system,
    );
  }
}

extension BuildContextThemeModeExt on BuildContext {
  ThemeModeProvider get themeModeReader => read<ThemeModeProvider>();
  ThemeModeProvider get themeModeWatcher => watch<ThemeModeProvider>();
  T themeModeSelector<T>(T Function(ThemeModeProvider) s) =>
      select<ThemeModeProvider, T>(s);
}

class ThemeModeProvider extends ChangeNotifier {
  ThemeModeOption _themeMode = ThemeModeOption.fromTitle(AppConf().themeMode);

  ThemeModeOption get themeMode => _themeMode;

  set themeMode(ThemeModeOption mode) {
    _themeMode = mode;
    AppConf().themeMode = mode.title;
    notifyListeners();
  }
}
