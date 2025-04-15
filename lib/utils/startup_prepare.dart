import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/utils/history_helper.dart';
import 'package:haka_comic/utils/images_helper.dart';
import 'package:haka_comic/utils/read_record_helper.dart';

class StartupPrepare {
  static Future<List<void>> prepare() async {
    await Future.wait([AppConf.initialize(), SetupConf.initialize()]);
    return Future.wait([
      HistoryHelper.instance.initialize(),
      ImagesHelper.instance.initialize(),
      ReadRecordHelper.instance.initialize(),
    ]);
  }
}
