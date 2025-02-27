import 'package:flutter/foundation.dart';
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

abstract class AsyncRequestHandler<T> extends ChangeNotifier {
  bool _isLoading = false;
  T? _data;
  Object? _error;

  bool get isLoading => _isLoading;
  T? get data => _data;
  Object? get error => _error;

  final void Function()? onBefore;
  final void Function(T)? onSuccess;
  final void Function(Object)? onError;
  final void Function()? onFinally;

  AsyncRequestHandler({
    this.onBefore,
    this.onSuccess,
    this.onError,
    this.onFinally,
  });

  void _commonSetup() {
    onBefore?.call();
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _commonFinally() {
    _isLoading = false;
    notifyListeners();
    onFinally?.call();
  }

  Future<void> refresh();
}

// 无参数版本
class AsyncRequestHandler0<T> extends AsyncRequestHandler<T> {
  final Future<T> Function() _fn;

  AsyncRequestHandler0(
    this._fn, {
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  Future<void> run() async {
    _commonSetup();
    try {
      final result = await _fn();
      _data = result;
      onSuccess?.call(result);
    } catch (e) {
      _error = e;
      onError?.call(e);
    } finally {
      _commonFinally();
    }
  }

  @override
  Future<void> refresh() async => await run();
}

// 单个参数版本
class AsyncRequestHandler1<T, P1> extends AsyncRequestHandler<T> {
  final Future<T> Function(P1) _fn;
  P1? _lastParam1;

  AsyncRequestHandler1(
    this._fn, {
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  Future<void> run(P1 param1) async {
    _lastParam1 = param1;
    _commonSetup();
    try {
      final result = await _fn(param1);
      _data = result;
      onSuccess?.call(result);
    } catch (e) {
      _error = e;
      onError?.call(e);
    } finally {
      _commonFinally();
    }
  }

  @override
  Future<void> refresh() async {
    if (_lastParam1 != null) {
      await run(_lastParam1 as P1);
    }
  }
}

// 两个参数版本
class AsyncRequestHandler2<T, P1, P2> extends AsyncRequestHandler<T> {
  final Future<T> Function(P1, P2) _fn;
  P1? _lastParam1;
  P2? _lastParam2;

  AsyncRequestHandler2(
    this._fn, {
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  Future<void> run(P1 param1, P2 param2) async {
    _lastParam1 = param1;
    _lastParam2 = param2;
    _commonSetup();
    try {
      final result = await _fn(param1, param2);
      _data = result;
      onSuccess?.call(result);
    } catch (e) {
      _error = e;
      onError?.call(e);
    } finally {
      _commonFinally();
    }
  }

  @override
  Future<void> refresh() async {
    if (_lastParam1 != null && _lastParam2 != null) {
      await run(_lastParam1 as P1, _lastParam2 as P2);
    }
  }
}

// 扩展方法
extension UseRequestExtensions<T> on Future<T> Function() {
  AsyncRequestHandler0<T> useRequest({
    void Function()? onBefore,
    void Function(T)? onSuccess,
    void Function(Object)? onError,
    void Function()? onFinally,
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

extension UseRequest1Extensions<T, P1> on Future<T> Function(P1) {
  AsyncRequestHandler1<T, P1> useRequest({
    void Function()? onBefore,
    void Function(T)? onSuccess,
    void Function(Object)? onError,
    void Function()? onFinally,
  }) {
    return AsyncRequestHandler1<T, P1>(
      this,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}

extension UseRequest2Extensions<T, P1, P2> on Future<T> Function(P1, P2) {
  AsyncRequestHandler2<T, P1, P2> useRequest({
    void Function()? onBefore,
    void Function(T)? onSuccess,
    void Function(Object)? onError,
    void Function()? onFinally,
  }) {
    return AsyncRequestHandler2<T, P1, P2>(
      this,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}
