import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class StartupPrepareUtils {
  static Future<List<void>> prepare() async {
    return Future.wait([_initSharedPreferencesUtilsAndAppConfig()]);
  }

  static Future<void> _initSharedPreferencesUtilsAndAppConfig() async {
    final prefs = await SharedPreferencesUtil.init();
    final List<String> keys = ['email', 'password', 'token'];
    final Map<String, String> values = Map.fromEntries(
      keys.map((key) => MapEntry(key, prefs.getString(key) ?? '')),
    );
    AppConfig.init(
      email: values['email']!,
      password: values['password']!,
      token: values['token']!,
    );
  }
}
