import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/download_manager.dart';
import 'package:window_manager/window_manager.dart';

class StartupPrepare {
  /// 初始化
  static Future<List<void>> prepare() async {
    await Future.wait([AppConf.initialize(), SetupConf.initialize()]);
    return Future.wait([
      HistoryHelper().initialize(),
      ImagesHelper.initialize(),
      ReadRecordHelper().initialize(),
      DownloadManager.initialize(),
      startDesktop(),
    ]);
  }
}

Future<void> startDesktop() async {
  if (isDesktop && kReleaseMode) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 620),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(750, 550));
      await windowManager.setResizable(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
