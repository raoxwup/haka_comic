import 'package:haka_comic/utils/request/request_handler_with_params.dart';
import 'package:haka_comic/utils/request/request_handler_without_params.dart';

extension RequestHandlerWithoutParamsExtensions<T> on Future<T> Function() {
  RequestHandlerWithoutParams<T> useRequest({
    bool manual = false,
    OnBeforeWithoutParam? onBefore,
    OnSuccessWithoutParam? onSuccess,
    OnErrorWithoutParam? onError,
    OnFinallyWithoutParam? onFinally,
  }) {
    return RequestHandlerWithoutParams<T>(
      this,
      manual: manual,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}

extension RequestHandlerWithParamsExtensions<T, P> on Future<T> Function(P) {
  RequestHandlerWithParams<T, P> useRequest({
    bool? manual,
    P? defaultParams,
    void Function(P)? onBefore,
    void Function(T, P)? onSuccess,
    void Function(Object, P)? onError,
    void Function(P)? onFinally,
  }) {
    return RequestHandlerWithParams<T, P>(
      this,
      manual: manual ?? false,
      defaultParams: defaultParams,
      onBefore: onBefore,
      onSuccess: onSuccess,
      onError: onError,
      onFinally: onFinally,
    );
  }
}
