import 'package:haka_comic/utils/shared_preferences_util.dart';

class AppConfig {
  static late AppConfig _instance;

  // 账号
  String _user;
  // 密码
  String _password;
  // token
  String _token;

  AppConfig._({
    required String user,
    required String password,
    required String token,
  }) : _user = user,
       _password = password,
       _token = token;

  factory AppConfig() => _instance;

  static void init({
    required String user,
    required String password,
    required String token,
  }) {
    _instance = AppConfig._(user: user, password: password, token: token);
  }

  // static get isLogged => _instance.user != '' && _instance.password != '';
  static get isLogged => _instance.token != '';

  set user(String user) {
    _instance._user = user;
    SharedPreferencesUtil.prefs.setString('user', user);
  }

  set password(String password) {
    _instance._password = password;
    SharedPreferencesUtil.prefs.setString('password', password);
  }

  set token(String token) {
    _instance._token = token;
    SharedPreferencesUtil.prefs.setString('token', token);
  }

  String get user => _instance._user;
  String get password => _instance._password;
  String get token => _instance._token;
}
