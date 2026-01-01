import 'package:flutter/material.dart';
import 'package:haka_comic/utils/request/request_state.dart';

abstract class RequestHandler<T, P> {
  RequestState<T> _state = const Initial();

  RequestState<T> get state => _state;

  VoidCallback? _notify;
  void bind(VoidCallback notify) => _notify = notify;
  void _setState(RequestState<T> Function(RequestState<T>) reducer) {
    _state = reducer(_state);
    _notify?.call();
  }

  bool manual;
  P? defaultParams;
  final void Function(P)? onBefore;
  final void Function(T, P)? onSuccess;
  final void Function(Object, P)? onError;
  final void Function(P)? onFinally;
  final T Function(T? prev, T current)? reducer;

  bool get keepData => reducer != null;

  RequestHandler({
    this.manual = false,
    this.reducer,
    this.defaultParams,
    this.onBefore,
    this.onSuccess,
    this.onError,
    this.onFinally,
  });

  void setup(P params) {
    onBefore?.call(params);
    _setState((s) => Loading(keepData ? s.data : null));
  }

  void success(T data, P params) {
    onSuccess?.call(data, params);
    if (keepData) data = reducer!(_state.data, data);
    _setState((s) => Success(data));
  }

  void fail(Object error, P params) {
    onError?.call(error, params);
    _setState((s) => Error(error));
  }

  void mutate(T data) => _setState((s) => Success(data));

  void apply([P? params]);

  void refresh();
}
