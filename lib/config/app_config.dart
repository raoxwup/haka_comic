import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';

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

  /// 启动时是否检查更新
  bool _checkUpdate = true;

  /// 漫画阅读方向
  ReadMode _readMode = ReadMode.vertical;

  /// 屏蔽
  List<String> _blacklist = [];

  /// 显示的分类
  List<String> _visibleCategories = [];

  /// webdav URL
  String _webdavUrl = '';

  /// webdav 用户名
  String _webdavUser = '';

  /// webdav 密码
  String _webdavPassword = '';

  /// 漫画显示模式
  ComicBlockMode _comicBlockMode = ComicBlockMode.detailed;

  /// 分页
  bool _pagination = true;

  /// Api
  Api _api = Api.web;

  /// 漫画块大小
  double _scale = 1.0;

  bool get isLogged => _token.isNotEmpty;
  bool get hasAccount => _email.isNotEmpty && _password.isNotEmpty;

  static Future<void> initialize() async {
    final prefs = await SharedPreferencesUtil.init();
    instance._email = prefs.getString('email') ?? '';
    instance._password = prefs.getString('password') ?? '';
    instance._token = prefs.getString('token') ?? '';
    instance._imageQuality = ImageQuality.fromName(
      prefs.getString('imageQuality'),
    );
    instance._checkUpdate = prefs.getBool('checkUpdate') ?? true;
    instance._readMode = stringToReadMode(
      prefs.getString('readMode') ?? ReadMode.vertical.name,
    );
    instance._blacklist = prefs.getStringList('blacklist') ?? [];
    instance._visibleCategories =
        prefs.getStringList('visibleCategories') ?? [];
    instance._webdavUrl = prefs.getString('webdavUrl') ?? '';
    instance._webdavUser = prefs.getString('webdavUser') ?? '';
    instance._webdavPassword = prefs.getString('webdavPassword') ?? '';
    instance._comicBlockMode = stringToComicBlockMode(
      prefs.getString('comicBlockMode') ?? '详细',
    );
    instance._pagination = prefs.getBool('pagination') ?? true;
    instance._api = Api.fromValue(prefs.getString('api') ?? Api.web.value);
    instance._scale = prefs.getDouble('scale') ?? 1.0;
  }

  set email(String value) {
    _email = value;
    SharedPreferencesUtil.prefs.setString('email', value);
  }

  set password(String value) {
    _password = value;
    SharedPreferencesUtil.prefs.setString('password', value);
  }

  set token(String value) {
    _token = value;
    SharedPreferencesUtil.prefs.setString('token', value);
  }

  set imageQuality(ImageQuality value) {
    _imageQuality = value;
    SharedPreferencesUtil.prefs.setString('imageQuality', value.name);
  }

  set checkUpdate(bool value) {
    _checkUpdate = value;
    SharedPreferencesUtil.prefs.setBool('checkUpdate', value);
  }

  set readMode(ReadMode value) {
    _readMode = value;
    SharedPreferencesUtil.prefs.setString('readMode', value.name);
  }

  set blacklist(List<String> value) {
    _blacklist = value;
    SharedPreferencesUtil.prefs.setStringList('blacklist', value);
  }

  set visibleCategories(List<String> value) {
    _visibleCategories = value;
    SharedPreferencesUtil.prefs.setStringList('visibleCategories', value);
  }

  set webdavUrl(String value) {
    _webdavUrl = value;
    SharedPreferencesUtil.prefs.setString('webdavUrl', value);
  }

  set webdavUser(String value) {
    _webdavUser = value;
    SharedPreferencesUtil.prefs.setString('webdavUser', value);
  }

  set webdavPassword(String value) {
    _webdavPassword = value;
    SharedPreferencesUtil.prefs.setString('webdavPassword', value);
  }

  set comicBlockMode(ComicBlockMode value) {
    _comicBlockMode = value;
    SharedPreferencesUtil.prefs.setString(
      'comicBlockMode',
      comicBlockModeToString(value),
    );
  }

  set pagination(bool value) {
    _pagination = value;
    SharedPreferencesUtil.prefs.setBool('pagination', value);
  }

  set api(Api value) {
    _api = value;
    SharedPreferencesUtil.prefs.setString('api', value.value);
  }

  set scale(double value) {
    _scale = value;
    SharedPreferencesUtil.prefs.setDouble('scale', value);
  }

  String get email => _email;
  String get password => _password;
  String get token => _token;
  ImageQuality get imageQuality => _imageQuality;
  bool get checkUpdate => _checkUpdate;
  ReadMode get readMode => _readMode;
  List<String> get blacklist => _blacklist;
  List<String> get visibleCategories => _visibleCategories;
  String get webdavUrl => _webdavUrl;
  String get webdavUser => _webdavUser;
  String get webdavPassword => _webdavPassword;
  ComicBlockMode get comicBlockMode => _comicBlockMode;
  bool get pagination => _pagination;
  Api get api => _api;
  double get scale => _scale;

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
    _checkUpdate = true;
    _readMode = ReadMode.vertical;
    _blacklist = [];
    _visibleCategories = [];
    _webdavUser = '';
    _webdavPassword = '';
    _webdavUrl = '';
    _comicBlockMode = ComicBlockMode.detailed;
    _pagination = true;
    _api = Api.web;
    _scale = 1.0;
    SharedPreferencesUtil.prefs.clear();
  }
}
