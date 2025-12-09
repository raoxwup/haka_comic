import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeModeOption>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeModeOption> {
  @override
  ThemeModeOption build() => ThemeModeOption.fromTitle(AppConf().themeMode);

  void updateThemeMode(ThemeModeOption mode) {
    AppConf().themeMode = mode.title;
    state = mode;
  }
}

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

final themeColorProvider =
    NotifierProvider<ThemeColorNotifier, ThemeColorOption>(
      ThemeColorNotifier.new,
    );

class ThemeColorNotifier extends Notifier<ThemeColorOption> {
  @override
  ThemeColorOption build() =>
      ThemeColorOption.fromTitle(AppConf().primaryColor);

  void updateThemeColor(ThemeColorOption color) {
    AppConf().primaryColor = color.title;
    state = color;
  }
}
