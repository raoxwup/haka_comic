import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';

class StartupPrepare {
  static Future<List<void>> prepare() async {
    return Future.wait([AppConf.initialize(), SetupConf.initialize()]);
  }
}
