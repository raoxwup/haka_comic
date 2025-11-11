import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';
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
      TagBlockHelper().initialize(),
      WordBlockHelper().initialize(),
      startDesktop(),
    ]);
  }
}

Future<void> startDesktop() async {
  if (isDesktop) {
    await windowManager.ensureInitialized();

    final conf = AppConf();
    final x = conf.windowX;
    final y = conf.windowY;
    final h = conf.windowHeight;
    final w = conf.windowWidth;
    final isFullscreen = conf.windowFullscreen;

    WindowOptions windowOptions = WindowOptions(
      size: Size(w, h),
      center: (x == null || y == null),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }

      await windowManager.setMinimumSize(const Size(750, 550));
      await windowManager.setResizable(true);
      await windowManager.show();
      await windowManager.focus();

      if (isFullscreen != null && isFullscreen) {
        await windowManager.setFullScreen(true);
      }
    });
  }
}
