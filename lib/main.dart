import 'dart:async';
import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/model/search_provider.dart';
import 'package:haka_comic/model/theme_provider.dart';
import 'package:haka_comic/model/user_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/startup_prepare.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/about/about.dart';
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
                  ChangeNotifierProvider(create: (_) => ReaderProvider()),
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
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (AppConf().checkUpdate) {
      checkUpdate();
    }
  }

  void checkUpdate() async {
    await Future.delayed(const Duration(seconds: 1));
    final result = await checkIsUpdated();
    if (result) {
      if (mounted) {
        showUpdateDialog();
      }
    }
  }

  ColorScheme _generateColorScheme(
    Color primaryColor, [
    Brightness? brightness,
  ]) {
    final ColorScheme newScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness ?? Brightness.light,
    );

    return newScheme.harmonized();
  }

  ThemeData getTheme(ColorScheme colorScheme, [Brightness? brightness]) =>
      ThemeData(
        colorScheme: colorScheme,
        brightness: brightness,
        fontFamily: Platform.isWindows ? '微软雅黑' : null,
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final (themeMode, color) = context
        .select<ThemeProvider, (ThemeMode, String)>(
          (data) => (data.themeMode, data.primaryColor),
        );
    return DynamicColorBuilder(
      builder: (light, dark) {
        final ColorScheme lightScheme, darkScheme;
        final Color primary;
        if (color != 'System' || light == null || dark == null) {
          primary = ThemeProvider.stringToColor(color);
        } else {
          primary = light.primary;
        }
        lightScheme = _generateColorScheme(primary);
        darkScheme = _generateColorScheme(primary, Brightness.dark);
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
