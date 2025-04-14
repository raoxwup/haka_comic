import 'package:flutter/material.dart';
import 'package:haka_comic/utils/log.dart';

extension WaitFuture<T> on Future<T> {
  Future<void> wait() async {
    try {
      await this;
    } catch (e) {
      Log.error('unexpected error', e);
    }
  }
}

abstract class AsyncRequestHandler<T, P> extends ChangeNotifier {
  bool isLoading = true;
  T? _data;
  Object? _error;
  bool _isDisposed = false;
  T? get data => _data;
  Object? get error => _error;

  final void Function(P)? onBefore;
  final void Function(T, P)? onSuccess;
  final void Function(Object, P)? onError;
  final void Function(P)? onFinally;

  AsyncRequestHandler({
    this.onBefore,
    this.onSuccess,
    this.onError,
    this.onFinally,
  });

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _commonSetup(P params) {
    if (_isDisposed) return;
    onBefore?.call(params);
    isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _commonFinally(P params) {
    if (_isDisposed) return;
    isLoading = false;
    notifyListeners();
    onFinally?.call(params);
  }

  Future<void> refresh();
}

// 无参数版本
class AsyncRequestHandler0<T> extends AsyncRequestHandler<T, void> {
  final Future<T> Function() _fn;

  AsyncRequestHandler0(
    this._fn, {
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  Future<void> run() async {
    _commonSetup(null);
    try {
      final result = await _fn();
      if (_isDisposed) return;
      _data = result;
      onSuccess?.call(result, null);
    } catch (e) {
      if (_isDisposed) return;
      _error = e;
      onError?.call(e, null);
    } finally {
      _commonFinally(null);
    }
  }

  @override
  Future<void> refresh() async => await run();
}

// 单个参数版本
class AsyncRequestHandler1<T, P> extends AsyncRequestHandler<T, P> {
  final Future<T> Function(P) _fn;
  P? _lastParam1;

  AsyncRequestHandler1(
    this._fn, {
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  Future<void> run(P param) async {
    _lastParam1 = param;
    _commonSetup(param);
    try {
      final result = await _fn(param);
      if (_isDisposed) return;
      _data = result;
      onSuccess?.call(result, param);
    } catch (e) {
      if (_isDisposed) return;
      _error = e;
      onError?.call(e, param);
    } finally {
      _commonFinally(param);
    }
  }

  @override
  Future<void> refresh() async {
    if (_lastParam1 != null) {
      await run(_lastParam1 as P);
    }
  }
}

// 扩展方法
extension UseRequestExtensions<T> on Future<T> Function() {
  AsyncRequestHandler0<T> useRequest({
    void Function(void)? onBefore,
    void Function(T, void)? onSuccess,
    void Function(Object, void)? onError,
    void Function(void)? onFinally,
  }) {
    return AsyncRequestHandler0<T>(
      this,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}

extension UseRequest1Extensions<T, P> on Future<T> Function(P) {
  AsyncRequestHandler1<T, P> useRequest({
    void Function(P)? onBefore,
    void Function(T, P)? onSuccess,
    void Function(Object, P)? onError,
    void Function(P)? onFinally,
  }) {
    return AsyncRequestHandler1<T, P>(
      this,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}

extension BuildContextExt on BuildContext {
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get left => padding.left;
  double get right => padding.right;
  double get top => padding.top;
  double get bottom => padding.bottom;

  Size get size => MediaQuery.sizeOf(this);
  double get width => size.width;
  double get height => size.height;

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
