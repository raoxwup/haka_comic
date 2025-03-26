import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/utils/history_helper.dart';

class StartupPrepare {
  static Future<List<void>> prepare() async {
    return Future.wait([
      AppConf.initialize(),
      SetupConf.initialize(),
    ]).then((_) => Future.wait([HistoryHelper.instance.initialize()]));
  }
}
