import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SetupConf {
  static final SetupConf _instance = SetupConf._internal();

  late String _dataPath;

  factory SetupConf() => _instance;

  SetupConf._internal();

  String get dataPath => _dataPath;

  static Future<void> initialize() async {
    await Future.wait([_instance._initPath()]);
  }

  Future<void> _initPath() async {
    _dataPath = (await getApplicationSupportDirectory()).path;
  }

  static SetupConf get instance => _instance;
}
