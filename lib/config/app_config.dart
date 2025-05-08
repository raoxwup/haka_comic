import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class AppConf {
  static final AppConf instance = AppConf._internal();

  AppConf._internal();

  factory AppConf() => instance;

  /// 账号
  String _email = '';

  /// 密码
  String _password = '';

  /// token
  String _token = '';

  /// 图片质量
  ImageQuality _imageQuality = ImageQuality.original;

  /// 分流
  Server _server = Server.one;

  bool get isLogged => _token.isNotEmpty;
  bool get hasAccount => _email.isNotEmpty && _password.isNotEmpty;

  static Future<void> initialize() async {
    final prefs = await SharedPreferencesUtil.init();
    instance._email = prefs.getString('email') ?? '';
    instance._password = prefs.getString('password') ?? '';
    instance._token = prefs.getString('token') ?? '';
    instance._imageQuality = getImageQuality(
      prefs.getString('imageQuality') ?? 'original',
    );
    instance._server = getServer(prefs.getString('server') ?? '1');
  }

  set email(String value) =>
      _saveToPrefs('email', value, value, (v) => _email = v);
  set password(String value) =>
      _saveToPrefs('password', value, value, (v) => _password = v);
  set token(String value) =>
      _saveToPrefs('token', value, value, (v) => _token = v);
  set imageQuality(ImageQuality value) => _saveToPrefs(
    'imageQuality',
    value.name,
    value,
    (v) => _imageQuality = value,
  );
  set server(Server value) => _saveToPrefs(
    'server',
    getServerName(value),
    value,
    (v) => _server = value,
  );

  String get email => _email;
  String get password => _password;
  String get token => _token;
  ImageQuality get imageQuality => _imageQuality;
  Server get server => _server;

  void _saveToPrefs<T>(
    String key,
    String value,
    T updateValue,
    Function(T) updateField,
  ) {
    updateField(updateValue);
    SharedPreferencesUtil.prefs.setString(key, value);
  }

  /// 清除token
  void clearAuth() {
    _token = '';
    SharedPreferencesUtil.prefs.remove('token');
  }

  /// 清空
  void clearCredentials() {
    _email = '';
    _password = '';
    _token = '';
    _imageQuality = ImageQuality.original;
    _server = Server.one;
    SharedPreferencesUtil.prefs
      ..remove('email')
      ..remove('password')
      ..remove('token')
      ..remove('imageQuality')
      ..remove('server');
  }
}
