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

  /// 条漫模式下翻页滑动距离 [n] * 屏幕高度
  double _slipFactor = 0.5;

  /// 是否启用音量键翻页
  bool _enableVolume = true;

  /// 竖向阅读菜单呼出占比
  double _verticalCenterFraction = 0.3;

  /// 横向阅读菜单呼出占比
  double _horizontalCenterFraction = 0.4;

  /// 窗口状态
  bool? _windowFullscreen;
  double? _windowX;
  double? _windowY;
  double? _windowWidth;
  double? _windowHeight;

  /// 翻页间隔
  int _interval = 5;

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
    instance._readMode = ReadMode.fromName(prefs.getString('readMode'));
    instance._blacklist = prefs.getStringList('blacklist') ?? [];
    instance._visibleCategories =
        prefs.getStringList('visibleCategories') ?? [];
    instance._webdavUrl = prefs.getString('webdavUrl') ?? '';
    instance._webdavUser = prefs.getString('webdavUser') ?? '';
    instance._webdavPassword = prefs.getString('webdavPassword') ?? '';
    instance._comicBlockMode = ComicBlockMode.fromDisplayName(
      prefs.getString('comicBlockMode'),
    );
    instance._pagination = prefs.getBool('pagination') ?? true;
    instance._api = Api.fromName(prefs.getString('api'));
    instance._scale = prefs.getDouble('scale') ?? 1.0;
    instance._slipFactor = prefs.getDouble('slipFactor') ?? 0.5;
    instance._enableVolume = prefs.getBool('enableVolume') ?? true;
    instance._verticalCenterFraction =
        prefs.getDouble('verticalCenterFraction') ?? 0.3;
    instance._horizontalCenterFraction =
        prefs.getDouble('horizontalCenterFraction') ?? 0.4;
    instance._windowFullscreen = prefs.getBool('windowFullscreen');
    instance._windowX = prefs.getDouble('windowX');
    instance._windowY = prefs.getDouble('windowY');
    instance._windowWidth = prefs.getDouble('windowWidth');
    instance._windowHeight = prefs.getDouble('windowHeight');
    instance._interval = prefs.getInt('interval') ?? 5;
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
    SharedPreferencesUtil.prefs.setString('comicBlockMode', value.displayName);
  }

  set pagination(bool value) {
    _pagination = value;
    SharedPreferencesUtil.prefs.setBool('pagination', value);
  }

  set api(Api value) {
    _api = value;
    SharedPreferencesUtil.prefs.setString('api', value.name);
  }

  set scale(double value) {
    _scale = value;
    SharedPreferencesUtil.prefs.setDouble('scale', value);
  }

  set slipFactor(double value) {
    _slipFactor = value;
    SharedPreferencesUtil.prefs.setDouble('slipFactor', value);
  }

  set enableVolume(bool value) {
    _enableVolume = value;
    SharedPreferencesUtil.prefs.setBool('enableVolume', value);
  }

  set verticalCenterFraction(double value) {
    _verticalCenterFraction = value;
    SharedPreferencesUtil.prefs.setDouble('verticalCenterFraction', value);
  }

  set horizontalCenterFraction(double value) {
    _horizontalCenterFraction = value;
    SharedPreferencesUtil.prefs.setDouble('horizontalCenterFraction', value);
  }

  set windowFullscreen(bool? value) {
    _windowFullscreen = value;
    if (value == null) return;
    SharedPreferencesUtil.prefs.setBool('windowFullscreen', value);
  }

  set windowX(double? value) {
    _windowX = value;
    if (value == null) return;
    SharedPreferencesUtil.prefs.setDouble('windowX', value);
  }

  set windowY(double? value) {
    _windowY = value;
    if (value == null) return;
    SharedPreferencesUtil.prefs.setDouble('windowY', value);
  }

  set windowWidth(double? value) {
    _windowWidth = value;
    if (value == null) return;
    SharedPreferencesUtil.prefs.setDouble('windowWidth', value);
  }

  set windowHeight(double? value) {
    _windowHeight = value;
    if (value == null) return;
    SharedPreferencesUtil.prefs.setDouble('windowHeight', value);
  }

  set interval(int value) {
    _interval = value;
    SharedPreferencesUtil.prefs.setInt('interval', value);
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
  double get slipFactor => _slipFactor;
  bool get enableVolume => _enableVolume;
  double get verticalCenterFraction => _verticalCenterFraction;
  double get horizontalCenterFraction => _horizontalCenterFraction;

  bool? get windowFullscreen => _windowFullscreen;
  double? get windowX => _windowX;
  double? get windowY => _windowY;
  double? get windowWidth => _windowWidth;
  double? get windowHeight => _windowHeight;

  int get interval => _interval;

  /// 清除token
  void clearAuth() {
    _token = '';
    SharedPreferencesUtil.prefs.remove('token');
  }
}
