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

  RequestHandler({
    this.manual = false,
    this.defaultParams,
    this.onBefore,
    this.onSuccess,
    this.onError,
    this.onFinally,
  });

  void setup(P params) {
    onBefore?.call(params);
    _setState((_) => const Loading());
  }

  void success(T data, P params) {
    onSuccess?.call(data, params);
    _setState((s) => Success(data));
  }

  void fail(Object error, P params) {
    onError?.call(error, params);
    _setState((s) => Error(error));
  }

  void apply([P? params]);

  void refresh();
}
