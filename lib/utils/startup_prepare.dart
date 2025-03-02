import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class StartupPrepareUtils {
  static Future<List<void>> prepare() async {
    return Future.wait([_initSharedPreferencesUtilsAndAppConfig()]);
  }

  static Future<void> _initSharedPreferencesUtilsAndAppConfig() async {
    final prefs = await SharedPreferencesUtil.init();
    AppConfig.init(
      user: prefs.getString('user') ?? '',
      password: prefs.getString('password') ?? '',
      token: prefs.getString('token') ?? '',
    );
  }
}
