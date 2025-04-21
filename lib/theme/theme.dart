import 'dart:io';
import 'package:flutter/material.dart';

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
  brightness: Brightness.light,
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
  brightness: Brightness.dark,
);

AppBarTheme getAppBarTheme(ColorScheme colorScheme) => AppBarTheme(
  scrolledUnderElevation: 0,
  surfaceTintColor: Colors.transparent,
  backgroundColor: colorScheme.surface,
);

ThemeData getDarkTheme(ColorScheme colorScheme) => ThemeData(
  colorScheme: colorScheme,
  appBarTheme: getAppBarTheme(colorScheme),
  fontFamily: Platform.isWindows ? 'HarmonyOS Sans SC' : null,
  brightness: Brightness.dark,
);

ThemeData getLightTheme(ColorScheme colorScheme) => ThemeData(
  colorScheme: colorScheme,
  appBarTheme: getAppBarTheme(colorScheme),
  fontFamily: Platform.isWindows ? 'HarmonyOS Sans SC' : null,
  brightness: Brightness.light,
);

ThemeData getTheme(ColorScheme colorScheme) => ThemeData(
  colorScheme: colorScheme,
  appBarTheme: getAppBarTheme(colorScheme),
  fontFamily: Platform.isWindows ? 'HarmonyOS Sans SC' : null,
);
