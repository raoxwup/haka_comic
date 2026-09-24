import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/local_favorites_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';
import 'package:haka_comic/network/proxy_controller.dart';
import 'package:haka_comic/rust/frb_generated.dart';
import 'package:haka_comic/network/proxy_overrides.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/views/download/download_storage_migration.dart';
import 'package:haka_comic/views/download/local_comic_importer.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:haka_comic/utils/log.dart';

class StartupPrepare {
  /// 初始化
  static Future<List<void>> prepare() async {
    await Future.wait([
      AppConf.initialize(),
      SetupConf.initialize(),
      RustLib.init(),
    ]);

    await _recoverPendingDownloadStorageOperations();

    // 在主 Isolate 安装全局代理覆盖层，所有 HttpClient 创建时都将经过此覆盖层。
    ProxyHttpOverrides.install();
    appProxyController.start();

    return Future.wait([
      HistoryHelper().initialize(),
      ImagesHelper().initialize(),
      ReadRecordHelper().initialize(),
      _initializeBackgroundDownloader(),
      TagBlockHelper().initialize(),
      WordBlockHelper().initialize(),
      DownloadTaskHelper().initialize(),
      LocalFavoritesHelper().initialize(),
      if (isAndroid) FlutterDisplayMode.setHighRefreshRate(),
      startDesktop(),
      Log.initialize(),
    ]);
  }
}

Future<void> _recoverPendingDownloadStorageOperations() async {
  try {
    await DownloadStorageMigrator.recoverPendingMigration();
  } catch (error, stackTrace) {
    Log.e(
      'Recover pending download storage migration failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
  try {
    await LocalComicImporter.recoverPendingImport();
  } catch (error, stackTrace) {
    Log.e(
      'Recover pending local comic import failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _initializeBackgroundDownloader() async {
  try {
    await BackgroundDownloader.initialize();
  } catch (error, stackTrace) {
    Log.e(
      'BackgroundDownloader initialization failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// 启动窗口 如果有上一次的窗口状态,则恢复
Future<void> startDesktop() async {
  if (isDesktop) {
    await windowManager.ensureInitialized();

    final conf = AppConf();
    final x = conf.windowX;
    final y = conf.windowY;
    final h = conf.windowHeight;
    final w = conf.windowWidth;
    final isFullscreen = conf.windowFullscreen;
    final shouldRestoreFullscreen = isFullscreen == true;

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

      await windowManager.setMinimumSize(const Size(780, 550));
      await windowManager.setResizable(true);

      if (shouldRestoreFullscreen) {
        await windowManager.setFullScreen(true);
      }

      await windowManager.show();
      await windowManager.focus();
    });
  }
}
