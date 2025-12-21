import 'package:haka_comic/utils/request/request_handler.dart';

typedef OnSuccessWithoutParam<T> = void Function(T data);
typedef OnErrorWithoutParam = void Function(Object error);
typedef OnBeforeWithoutParam = void Function();
typedef OnFinallyWithoutParam = void Function();

class RequestHandlerWithoutParams<T> extends RequestHandler<T, void> {
  final Future<T> Function() request;

  RequestHandlerWithoutParams(
    this.request, {
    super.manual,
    OnBeforeWithoutParam? onBefore,
    OnSuccessWithoutParam<T>? onSuccess,
    OnErrorWithoutParam? onError,
    OnFinallyWithoutParam? onFinally,
  }) : super(
         onBefore: onBefore == null ? null : (_) => onBefore(),
         onSuccess: onSuccess == null ? null : (data, _) => onSuccess(data),
         onError: onError == null ? null : (err, _) => onError(err),
         onFinally: onFinally == null ? null : (_) => onFinally(),
       );

  Future<void> run() async {
    setup(null);
    try {
      final data = await request();
      success(data, null);
    } catch (e) {
      fail(e, null);
    } finally {
      onFinally?.call(null);
    }
  }

  @override
  void apply([_]) => run();

  @override
  void refresh() => run();
}
