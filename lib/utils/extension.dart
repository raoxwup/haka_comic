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

abstract class AsyncRequestHandler<T, P> extends ChangeNotifier {
  bool _isLoading = false;
  T? _data;
  Object? _error;

  bool get isLoading => _isLoading;
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

  void _commonSetup(P params) {
    onBefore?.call(params);
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _commonFinally(P params) {
    _isLoading = false;
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
      _data = result;
      onSuccess?.call(result, null);
    } catch (e) {
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
      _data = result;
      onSuccess?.call(result, param);
    } catch (e) {
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

// 两个参数版本
// class AsyncRequestHandler2<T, P1, P2> extends AsyncRequestHandler<T, P1, P2> {
//   final Future<T> Function(P1, P2) _fn;
//   P1? _lastParam1;
//   P2? _lastParam2;

//   AsyncRequestHandler2(
//     this._fn, {
//     super.onBefore,
//     super.onSuccess,
//     super.onError,
//     super.onFinally,
//   });

//   Future<void> run(P1 param1, P2 param2) async {
//     _lastParam1 = param1;
//     _lastParam2 = param2;
//     _commonSetup(param1, param2);
//     try {
//       final result = await _fn(param1, param2);
//       _data = result;
//       onSuccess?.call(result, param1, param2);
//     } catch (e) {
//       _error = e;
//       onError?.call(e, param1, param2);
//     } finally {
//       _commonFinally(param1, param2);
//     }
//   }

//   @override
//   Future<void> refresh() async {
//     if (_lastParam1 != null && _lastParam2 != null) {
//       await run(_lastParam1 as P1, _lastParam2 as P2);
//     }
//   }
// }

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

// extension UseRequest2Extensions<T, P1, P2> on Future<T> Function(P1, P2) {
//   AsyncRequestHandler2<T, P1, P2> useRequest({
//     void Function(P1, P2)? onBefore,
//     void Function(T, P1, P2)? onSuccess,
//     void Function(Object, P1, P2)? onError,
//     void Function(P1, P2)? onFinally,
//   }) {
//     return AsyncRequestHandler2<T, P1, P2>(
//       this,
//       onBefore: onBefore,
//       onSuccess: onSuccess,
//       onError: onError,
//       onFinally: onFinally,
//     );
//   }
// }
