import 'package:flutter/foundation.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/shared_preferences_utils.dart';

class AsyncRequestHandler<T> extends ChangeNotifier {
  bool _isLoading = false;
  T? _data;
  Object? _error;

  bool get isLoading => _isLoading;
  T? get data => _data;
  Object? get error => _error;

  final Future<T> Function() _futureFunction;

  AsyncRequestHandler(this._futureFunction);

  Future<void> run() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _futureFunction();
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

extension UseRequest<T> on Future<T> Function() {
  AsyncRequestHandler<T> useRequest() {
    return AsyncRequestHandler<T>(this);
  }
}

extension WaitFuture<T> on Future<T> {
  Future<void> wait() async {
    try {
      await this;
    } catch (e) {
      print(e.toString());
    }
  }
}

class StartupPrepareUtils {
  static Future<List<void>> prepare() async {
    return Future.wait([_initSharedPreferencesUtilsAndAppConfig()]);
  }

  static Future<void> _initSharedPreferencesUtilsAndAppConfig() async {
    final prefs = await SharedPreferencesUtils.init();
    AppConfig.init(
      user: prefs.getString('user') ?? '',
      password: prefs.getString('password') ?? '',
    );
  }
}
