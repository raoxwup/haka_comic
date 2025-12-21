import 'package:haka_comic/utils/request/request_handler.dart';

class RequestHandlerWithParams<T, P> extends RequestHandler<T, P> {
  late P _lastParam;

  final Future<T> Function(P) request;

  RequestHandlerWithParams(
    this.request, {
    super.manual,
    super.defaultParams,
    super.onBefore,
    super.onSuccess,
    super.onError,
    super.onFinally,
  });

  @override
  void apply([P? params]) {
    assert(params != null);
    if (params == null) return;
    run(params);
  }

  @override
  void refresh() {
    if (_lastParam == null) {
      throw Exception('you must call apply or run first');
    }
    run(_lastParam);
  }

  Future<void> run(P params) async {
    _lastParam = params;
    setup(params);
    try {
      final data = await request(params);
      success(data, params);
    } catch (e) {
      fail(e, params);
    } finally {
      onFinally?.call(params);
    }
  }
}
