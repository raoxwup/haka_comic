import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';

class AppConf {
  static final AppConf instance = AppConf._internal();

  AppConf._internal();

  factory AppConf() => instance;

  /// 主题模式
  String _themeMode = 'System';

  /// 主题颜色
  String _primaryColor = 'System';

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

  /// 搜索历史
  List<String> _searchHistory = [];

  /// 窗口状态
  bool? _windowFullscreen;
  double? _windowX;
  double? _windowY;
  double? _windowWidth;
  double? _windowHeight;

  /// 翻页间隔
  int _interval = 5;

  /// 是否需要身份认证
  bool _needAuth = false;

  /// 条漫模式列表宽度占屏幕宽度的百分比
  double _verticalListWidthRatio = 1.0;

  bool get isLogged => _token.isNotEmpty;
  bool get hasAccount => _email.isNotEmpty && _password.isNotEmpty;

  static Future<void> initialize() async {
    final prefsWithCache = await SharedPreferencesUtil.init();
    instance._email = prefsWithCache.getString('email') ?? '';
    instance._password = prefsWithCache.getString('password') ?? '';
    instance._token = prefsWithCache.getString('token') ?? '';
    instance._imageQuality = ImageQuality.fromName(
      prefsWithCache.getString('imageQuality'),
    );
    instance._checkUpdate = prefsWithCache.getBool('checkUpdate') ?? true;
    instance._readMode = ReadMode.fromName(
      prefsWithCache.getString('readMode'),
    );
    instance._blacklist = prefsWithCache.getStringList('blacklist') ?? [];
    instance._visibleCategories =
        prefsWithCache.getStringList('visibleCategories') ?? [];
    instance._webdavUrl = prefsWithCache.getString('webdavUrl') ?? '';
    instance._webdavUser = prefsWithCache.getString('webdavUser') ?? '';
    instance._webdavPassword = prefsWithCache.getString('webdavPassword') ?? '';
    instance._comicBlockMode = ComicBlockMode.fromDisplayName(
      prefsWithCache.getString('comicBlockMode'),
    );
    instance._pagination = prefsWithCache.getBool('pagination') ?? true;
    instance._api = Api.fromName(prefsWithCache.getString('api'));
    instance._scale = prefsWithCache.getDouble('scale') ?? 1.0;
    instance._slipFactor = prefsWithCache.getDouble('slipFactor') ?? 0.5;
    instance._enableVolume = prefsWithCache.getBool('enableVolume') ?? true;
    instance._verticalCenterFraction =
        prefsWithCache.getDouble('verticalCenterFraction') ?? 0.3;
    instance._horizontalCenterFraction =
        prefsWithCache.getDouble('horizontalCenterFraction') ?? 0.4;
    instance._windowFullscreen = prefsWithCache.getBool('windowFullscreen');
    instance._windowX = prefsWithCache.getDouble('windowX');
    instance._windowY = prefsWithCache.getDouble('windowY');
    instance._windowWidth = prefsWithCache.getDouble('windowWidth');
    instance._windowHeight = prefsWithCache.getDouble('windowHeight');
    instance._interval = prefsWithCache.getInt('interval') ?? 5;
    instance._themeMode = prefsWithCache.getString('theme_mode') ?? 'System';
    instance._primaryColor =
        prefsWithCache.getString('primary_color') ?? 'System';
    instance._searchHistory =
        prefsWithCache.getStringList('search_history') ?? [];
    instance._needAuth = prefsWithCache.getBool('needAuth') ?? false;
    instance._verticalListWidthRatio =
        prefsWithCache.getDouble('verticalListWidthRatio') ?? 1.0;
  }

  set email(String value) {
    _email = value;
    SharedPreferencesUtil.prefsWithCache.setString('email', value);
  }

  set password(String value) {
    _password = value;
    SharedPreferencesUtil.prefsWithCache.setString('password', value);
  }

  set token(String value) {
    _token = value;
    SharedPreferencesUtil.prefsWithCache.setString('token', value);
  }

  set imageQuality(ImageQuality value) {
    _imageQuality = value;
    SharedPreferencesUtil.prefsWithCache.setString('imageQuality', value.name);
  }

  set checkUpdate(bool value) {
    _checkUpdate = value;
    SharedPreferencesUtil.prefsWithCache.setBool('checkUpdate', value);
  }

  set readMode(ReadMode value) {
    _readMode = value;
    SharedPreferencesUtil.prefsWithCache.setString('readMode', value.name);
  }

  set blacklist(List<String> value) {
    _blacklist = value;
    SharedPreferencesUtil.prefsWithCache.setStringList('blacklist', value);
  }

  set visibleCategories(List<String> value) {
    _visibleCategories = value;
    SharedPreferencesUtil.prefsWithCache.setStringList(
      'visibleCategories',
      value,
    );
  }

  set webdavUrl(String value) {
    _webdavUrl = value;
    SharedPreferencesUtil.prefsWithCache.setString('webdavUrl', value);
  }

  set webdavUser(String value) {
    _webdavUser = value;
    SharedPreferencesUtil.prefsWithCache.setString('webdavUser', value);
  }

  set webdavPassword(String value) {
    _webdavPassword = value;
    SharedPreferencesUtil.prefsWithCache.setString('webdavPassword', value);
  }

  set comicBlockMode(ComicBlockMode value) {
    _comicBlockMode = value;
    SharedPreferencesUtil.prefsWithCache.setString(
      'comicBlockMode',
      value.displayName,
    );
  }

  set pagination(bool value) {
    _pagination = value;
    SharedPreferencesUtil.prefsWithCache.setBool('pagination', value);
  }

  set api(Api value) {
    _api = value;
    SharedPreferencesUtil.prefsWithCache.setString('api', value.name);
  }

  set scale(double value) {
    _scale = value;
    SharedPreferencesUtil.prefsWithCache.setDouble('scale', value);
  }

  set slipFactor(double value) {
    _slipFactor = value;
    SharedPreferencesUtil.prefsWithCache.setDouble('slipFactor', value);
  }

  set enableVolume(bool value) {
    _enableVolume = value;
    SharedPreferencesUtil.prefsWithCache.setBool('enableVolume', value);
  }

  set verticalCenterFraction(double value) {
    _verticalCenterFraction = value;
    SharedPreferencesUtil.prefsWithCache.setDouble(
      'verticalCenterFraction',
      value,
    );
  }

  set horizontalCenterFraction(double value) {
    _horizontalCenterFraction = value;
    SharedPreferencesUtil.prefsWithCache.setDouble(
      'horizontalCenterFraction',
      value,
    );
  }

  set windowFullscreen(bool? value) {
    _windowFullscreen = value;
    if (value == null) return;
    SharedPreferencesUtil.prefsWithCache.setBool('windowFullscreen', value);
  }

  set windowX(double? value) {
    _windowX = value;
    if (value == null) return;
    SharedPreferencesUtil.prefsWithCache.setDouble('windowX', value);
  }

  set windowY(double? value) {
    _windowY = value;
    if (value == null) return;
    SharedPreferencesUtil.prefsWithCache.setDouble('windowY', value);
  }

  set windowWidth(double? value) {
    _windowWidth = value;
    if (value == null) return;
    SharedPreferencesUtil.prefsWithCache.setDouble('windowWidth', value);
  }

  set windowHeight(double? value) {
    _windowHeight = value;
    if (value == null) return;
    SharedPreferencesUtil.prefsWithCache.setDouble('windowHeight', value);
  }

  set interval(int value) {
    _interval = value;
    SharedPreferencesUtil.prefsWithCache.setInt('interval', value);
  }

  set themeMode(String value) {
    _themeMode = value;
    SharedPreferencesUtil.prefsWithCache.setString('theme_mode', value);
  }

  set primaryColor(String value) {
    _primaryColor = value;
    SharedPreferencesUtil.prefsWithCache.setString('primary_color', value);
  }

  set searchHistory(List<String> value) {
    _searchHistory = value;
    SharedPreferencesUtil.prefsWithCache.setStringList('search_history', value);
  }

  set needAuth(bool value) {
    _needAuth = value;
    SharedPreferencesUtil.prefsWithCache.setBool('needAuth', value);
  }

  set verticalListWidthRatio(double value) {
    _verticalListWidthRatio = value;
    SharedPreferencesUtil.prefsWithCache.setDouble(
      'verticalListWidthRatio',
      value,
    );
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
  String get themeMode => _themeMode;
  String get primaryColor => _primaryColor;
  List<String> get searchHistory => _searchHistory;
  bool get needAuth => _needAuth;
  double get verticalListWidthRatio => _verticalListWidthRatio;

  /// 清除token
  void clearAuth() {
    _token = '';
    SharedPreferencesUtil.prefsWithCache.remove('token');
  }
}
