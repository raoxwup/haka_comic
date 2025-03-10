import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/startup_prepare.dart';
import 'package:haka_comic/utils/extension.dart';

void main(List<String> args) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      StartupPrepareUtils.prepare().then((_) => runApp(const App())).wait();
    },
    (Object error, StackTrace stackTrace) {
      Log.error('runZonedGuarded', error, stackTrace);
    },
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "HaKa Comic",
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppConfig.appScaffoldMessengerKey,
    );
  }
}
