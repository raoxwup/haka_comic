import 'dart:async';
import 'package:flutter/material.dart';

import 'package:haka_comic/router/router.dart' as app_router;
import 'package:haka_comic/utils/startup_prepare_utils.dart';

void main(List<String> args) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      StartupPrepareUtils.prepare().then((_) => runApp(const App())).wait();
    },
    (Object error, StackTrace stackTrace) {
      debugPrint(
        'runZonedGuarded: Caught error in my root zone. $error. $stackTrace.',
      );
    },
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "HaKa Comic",
      routerConfig: app_router.Router.router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
