import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/download_manager.dart';

class StartupPrepare {
  /// 初始化
  static Future<List<void>> prepare() async {
    await Future.wait([AppConf.initialize(), SetupConf.initialize()]);
    return Future.wait([
      HistoryHelper().initialize(),
      ImagesHelper.initialize(),
      ReadRecordHelper().initialize(),
      DownloadManager.initialize(),
    ]);
  }
}
