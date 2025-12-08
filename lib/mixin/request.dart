import 'dart:async' show scheduleMicrotask;
import 'package:flutter/material.dart';

mixin UseRequestMixin<T extends StatefulWidget> on State<T> {
  List<AsyncRequestHandler> registerHandler();

  bool _scheduled = false;
  bool _dirty = false;

  void _scheduleRebuild() {
    if (_scheduled) return;
    _scheduled = true;

    scheduleMicrotask(() {
      if (mounted && _dirty) {
        setState(() {});
      }
      _dirty = false;
      _scheduled = false;
    });
  }

  R _register<R extends AsyncRequestHandler>(R handler) {
    handler.bind(() {
      _dirty = true;
      _scheduleRebuild();
    });
    if (!handler.manual) {
      handler.run(handler.initParam);
    }
    return handler;
  }

  @override
  void initState() {
    super.initState();
    final handlers = registerHandler();
    for (final handler in handlers) {
      _register(handler);
    }
  }
}

abstract class BaseRequestHandler<T, P> {
  T? get data;
  Object? get error;
  bool get loading;
  bool get hasError;
  bool get hasData;

  Future<void> refresh();

  Future<void> run(P? param);
}

abstract class AsyncRequestHandler<T, P> implements BaseRequestHandler<T, P> {
  T? _data;
  Object? _error;
  bool _loading = false;

  bool _hasRequested = false;

  @override
  T? get data => _data;

  @override
  Object? get error => _error;

  @override
  bool get loading => _loading;

  bool manual = false;
  P? initParam;
  final void Function(P)? onBefore;
  final void Function(T, P)? onSuccess;
  final void Function(Object, P)? onError;
  final void Function(P)? onFinally;

  AsyncRequestHandler({
    this.manual = false,
    this.initParam,
    this.onBefore,
    this.onSuccess,
    this.onError,
    this.onFinally,
  });

  VoidCallback? _notify;

  void bind(VoidCallback notify) => _notify = notify;

  void _setup(P params) {
    _loading = true;
    _error = null;
    onBefore?.call(params);
    _notify?.call();
  }

  void _finally(P params) {
    _loading = false;
    onFinally?.call(params);
    _notify?.call();
  }

  @override
  bool get hasError => error != null;
  @override
  bool get hasData => data != null;

  bool get isIdle =>
      !_hasRequested && !_loading && _data == null && _error == null;
}

class AsyncRequestHandlerWithoutParam<T> extends AsyncRequestHandler<T, void> {
  final Future<T> Function() _fn;

  AsyncRequestHandlerWithoutParam(
    this._fn, {
    super.manual,
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  @override
  Future<void> run(_) async {
    if (!_hasRequested) {
      _hasRequested = true;
    }
    _setup(null);
    try {
      final result = await _fn();
      _data = result;
      onSuccess?.call(result, null);
    } catch (e) {
      _error = e;
      onError?.call(e, null);
    } finally {
      _finally(null);
    }
  }

  @override
  Future<void> refresh() => run(null);
}

class AsyncRequestHandlerWithParam<T, P> extends AsyncRequestHandler<T, P> {
  P? _lastParam;

  final Future<T> Function(P) _fn;

  AsyncRequestHandlerWithParam(
    this._fn, {
    super.initParam,
    super.manual,
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  @override
  Future<void> run(P? param) async {
    if (param == null) return;
    if (!_hasRequested) {
      _hasRequested = true;
    }
    _lastParam = param;
    _setup(param);
    try {
      final result = await _fn(param);
      _data = result;
      onSuccess?.call(result, param);
    } catch (e) {
      _error = e;
      onError?.call(e, param);
    } finally {
      _finally(param);
    }
  }

  @override
  Future<void> refresh() => run(_lastParam ?? initParam);
}

extension UseRequestWithoutParamExtensions<T> on Future<T> Function() {
  AsyncRequestHandlerWithoutParam<T> useRequest({
    bool manual = false,
    void Function(void)? onBefore,
    void Function(T, void)? onSuccess,
    void Function(Object, void)? onError,
    void Function(void)? onFinally,
  }) {
    return AsyncRequestHandlerWithoutParam<T>(
      this,
      manual: manual,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}

extension UseRequestWithParamExtensions<T, P> on Future<T> Function(P) {
  AsyncRequestHandlerWithParam<T, P> useRequest({
    bool manual = false,
    P? initParam,
    void Function(P)? onBefore,
    void Function(T, P)? onSuccess,
    void Function(Object, P)? onError,
    void Function(P)? onFinally,
  }) {
    return AsyncRequestHandlerWithParam<T, P>(
      this,
      initParam: initParam,
      manual: manual,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}
