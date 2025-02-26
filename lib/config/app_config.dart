import 'package:haka_comic/utils/shared_preferences_utils.dart';

class AppConfig {
  static late AppConfig _instance;

  // 账号
  String _user;
  // 密码
  String _password;

  AppConfig._({required String user, required String password})
    : _user = user,
      _password = password;

  factory AppConfig() => _instance;

  static void init({required String user, required String password}) {
    _instance = AppConfig._(user: user, password: password);
  }

  static get isLogged => _instance.user != '' && _instance.password != '';

  set user(String user) {
    _instance._user = user;
    SharedPreferencesUtils.prefs.setString('user', user);
  }

  set password(String password) {
    _instance._password = password;
    SharedPreferencesUtils.prefs.setString('password', password);
  }

  String get user => _instance._user;
  String get password => _instance._password;
}
