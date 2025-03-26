import 'package:haka_comic/utils/shared_preferences_util.dart';

class AppConf {
  static final AppConf instance = AppConf._internal();

  String _email = '';
  String _password = '';
  String _token = '';

  AppConf._internal();

  bool get isLogged => _token.isNotEmpty;
  bool get hasAccount => _email.isNotEmpty && _password.isNotEmpty;

  static Future<void> initialize() async {
    final prefs = await SharedPreferencesUtil.init();
    instance._email = prefs.getString('email') ?? '';
    instance._password = prefs.getString('password') ?? '';
    instance._token = prefs.getString('token') ?? '';
  }

  set email(String value) => _saveToPrefs('email', value, (v) => _email = v);
  set password(String value) =>
      _saveToPrefs('password', value, (v) => _password = v);
  set token(String value) => _saveToPrefs('token', value, (v) => _token = v);

  String get email => _email;
  String get password => _password;
  String get token => _token;

  void _saveToPrefs(String key, String value, Function(String) updateField) {
    updateField(value);
    SharedPreferencesUtil.prefs.setString(key, value);
  }

  void clearAuth() {
    _token = '';
    SharedPreferencesUtil.prefs.remove('token');
  }

  void clearCredentials() {
    _email = '';
    _password = '';
    _token = '';
    SharedPreferencesUtil.prefs
      ..remove('email')
      ..remove('password')
      ..remove('token');
  }
}
