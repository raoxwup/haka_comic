import 'package:haka_comic/utils/shared_preferences_utils.dart';

class AppConfig {
  static AppConfig? _instance;

  // 账号
  String _user;
  // 密码
  String _password;

  AppConfig._({required String user, required String password})
    : _user = user,
      _password = password;

  factory AppConfig() {
    if (_instance == null) {
      throw Exception(
        'AppConfig has not been initialized. Call AppConfig.init() first.',
      );
    }
    return _instance!;
  }

  static void init({required String user, required String password}) {
    if (_instance == null) {
      _instance = AppConfig._(user: user, password: password);
    } else {
      throw Exception('AppConfig is already initialized.');
    }
  }

  get isLogged => _instance!.user != '' && _instance!.password != '';

  set user(String user) {
    _instance!._user = user;
    SharedPreferencesUtils.prefs.setString('user', user);
  }

  set password(String password) {
    _instance!._password = password;
    SharedPreferencesUtils.prefs.setString('password', password);
  }

  String get user => _instance!._user;
  String get password => _instance!._password;
}
