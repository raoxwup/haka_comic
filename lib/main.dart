import 'dart:async';
import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/model/theme_provider.dart';
import 'package:haka_comic/model/user_provider.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/theme/theme.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/startup_prepare.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:provider/provider.dart';

void main(List<String> args) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      StartupPrepare.prepare()
          .then(
            (_) => runApp(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => ThemeProvider()),
                  ChangeNotifierProvider(create: (_) => SearchProvider()),
                  ChangeNotifierProvider(create: (_) => UserProvider()),
                ],
                child: const App(),
              ),
            ),
          )
          .wait();
    },
    (Object error, StackTrace stackTrace) {
      Log.error('runZonedGuarded', error, stackTrace);
    },
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.initState();
  }

  ColorScheme _generateColorScheme(
    Color? primaryColor, [
    Brightness? brightness,
  ]) {
    final Color seedColor = primaryColor ?? kFallbackAccentColor;

    final ColorScheme newScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness ?? Brightness.light,
    );

    return newScheme.harmonized();
  }

  ThemeData getTheme(ColorScheme colorScheme, [Brightness? brightness]) =>
      ThemeData(
        colorScheme: colorScheme,
        brightness: brightness,
        // 调试模式下使用
        fontFamily: Platform.isWindows ? 'HarmonyOS Sans SC' : null,
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (data) => data.themeMode,
    );
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightScheme = _generateColorScheme(
          lightDynamic?.primary,
        );
        final ColorScheme darkScheme = _generateColorScheme(
          darkDynamic?.primary,
          Brightness.dark,
        );
        return MaterialApp.router(
          title: "HaKa Comic",
          routerConfig: appRouter,
          theme: getTheme(lightScheme),
          darkTheme: getTheme(darkScheme, Brightness.dark),
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          builder: (context, child) {
            return _SystemUiProvider(child!);
          },
        );
      },
    );
  }
}

class _SystemUiProvider extends StatelessWidget {
  const _SystemUiProvider(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var brightness = Theme.of(context).brightness;
    SystemUiOverlayStyle systemUiStyle;
    if (brightness == Brightness.light) {
      systemUiStyle = SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
    } else {
      systemUiStyle = SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: child,
    );
  }
}
