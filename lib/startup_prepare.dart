import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';
import 'package:haka_comic/rust/frb_generated.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class StartupPrepare {
  /// 初始化
  static Future<List<void>> prepare() async {
    await Future.wait([
      AppConf.initialize(),
      SetupConf.initialize(),
      RustLib.init(),
    ]);
    return Future.wait([
      HistoryHelper().initialize(),
      ImagesHelper().initialize(),
      ReadRecordHelper().initialize(),
      BackgroundDownloader.initialize(),
      TagBlockHelper().initialize(),
      WordBlockHelper().initialize(),
      DownloadTaskHelper().initialize(),
      if (isAndroid) FlutterDisplayMode.setHighRefreshRate(),
      startDesktop(),
    ]);
  }
}

/// 启动窗口 如果有上一次的窗口状态,则恢复
Future<void> startDesktop() async {
  if (isDesktop && kReleaseMode) {
    await windowManager.ensureInitialized();

    final conf = AppConf();
    final x = conf.windowX;
    final y = conf.windowY;
    final h = conf.windowHeight;
    final w = conf.windowWidth;
    final isFullscreen = conf.windowFullscreen;

    // 默认窗口大小
    final defaultSize = const Size(900.0, 620.0);

    WindowOptions windowOptions = WindowOptions(
      size: (w != null && h != null) ? Size(w, h) : defaultSize,
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
