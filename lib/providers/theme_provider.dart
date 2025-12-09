import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeState {
  final ThemeMode themeMode;
  final String primaryColor;
  ThemeState({required this.themeMode, required this.primaryColor});

  ThemeState copyWith({ThemeMode? themeMode, String? primaryColor}) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        primaryColor: primaryColor ?? this.primaryColor,
      );
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeState> {
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

  @override
  ThemeState build() => ThemeState(
    themeMode: stringToThemeMode[AppConf().themeMode]!,
    primaryColor: AppConf().primaryColor,
  );

  void setThemeMode(ThemeMode mode) {
    AppConf().themeMode = themeModeToString[mode]!;
    state = state.copyWith(themeMode: mode);
  }

  void setPrimaryColor(String color) {
    AppConf().primaryColor = color;
    state = state.copyWith(primaryColor: color);
  }
}
