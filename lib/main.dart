import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/model/app_data.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/theme/theme.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/startup_prepare.dart';
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
                providers: [ChangeNotifierProvider(create: (_) => AppData())],
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "HaKa Comic",
      routerConfig: appRouter,
      theme: getLightTheme(lightColorScheme),
      darkTheme: getDarkTheme(darkColorScheme),
      themeMode: context.select<AppData, ThemeMode>((data) => data.themeMode),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) {
        return _SystemUiProvider(child!);
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
