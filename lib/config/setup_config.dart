import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SetupConf {
  static late String dataPath;
  static String appVersion = "1.0.0-beta.6";

  static Future<void> initialize() async {
    await Future.wait([initPath()]);
  }

  static Future<void> initPath() async {
    final dir = await getApplicationDocumentsDirectory();
    dataPath = dir.path;
  }
}
