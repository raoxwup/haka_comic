import 'package:dio/dio.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/common.dart';

class Client {
  static const _maxRetries = 3;

  static CancelToken _cancelToken = CancelToken();

  static void setBaseUrl(String url) => _client.options.baseUrl = url;

  static final Dio _client = Dio(
      BaseOptions(
        baseUrl: AppConf().api.host,
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 10),
        validateStatus: (status) {
          return status == 200 || status == 400 || status == 401;
        },
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          bool shouldRetry = false;
          if (err.response != null) {
            final sc = err.response!.statusCode;
            if (sc != null && sc >= 500 && sc < 600) shouldRetry = true;
          } else {
            final t = err.type;
            shouldRetry =
                t == DioExceptionType.connectionTimeout ||
                t == DioExceptionType.sendTimeout ||
                t == DioExceptionType.receiveTimeout ||
                t == DioExceptionType.connectionError;
          }

          final extra = err.requestOptions.extra;
          int retryCount = extra['retryCount'] ?? 0;
          if (shouldRetry && retryCount < _maxRetries - 1) {
            await Future.delayed(const Duration(seconds: 1));
            final reqOpt = err.requestOptions;
            reqOpt.extra['retryCount'] = retryCount + 1;
            try {
              final ret = await _client.fetch(reqOpt);
              return handler.resolve(ret);
            } catch (_) {
              return handler.reject(err);
            }
          }
          return handler.reject(err);
        },
      ),
    );

  static Future<Map<String, dynamic>> _request(
    Method method,
    String path, {
    Map<String, dynamic>? payload,
    String? baseUrl,
  }) async {
    String queryString = '';
    if (method == Method.get) {
      queryString =
          Uri(
            queryParameters: (payload ?? {}).map(
              (key, value) => MapEntry(key, value.toString()),
            ),
          ).query;
    }
    final headers =
        method == Method.get
            ? getHeaders(
              queryString.isEmpty ? path : '$path?$queryString',
              method,
            )
            : getHeaders(path, method);
    _client.options.headers = headers;
    if (baseUrl != null) {
      _client.options.baseUrl = baseUrl;
    }
    try {
      Response response;
      switch (method) {
        case Method.get:
          response = await _client.get(
            path,
            queryParameters: payload,
            cancelToken: _cancelToken,
          );
          break;
        case Method.post:
          response = await _client.post(
            path,
            data: payload,
            cancelToken: _cancelToken,
          );
          break;
        case Method.put:
          response = await _client.put(
            path,
            data: payload,
            cancelToken: _cancelToken,
          );
          break;
        case Method.delete:
          response = await _client.delete(
            path,
            data: payload,
            cancelToken: _cancelToken,
          );
          break;
      }
      if (response.data == null) {
        throw Exception("Empty data");
      }
      switch (response.statusCode) {
        case 200:
          return response.data;
        case 400:
          var data = response.data;
          throw data['message'];
        case 401:
          _cancelToken.cancel();
          _cancelToken = CancelToken();
          logout();
          throw '登录失效';
        default:
          throw Exception("Invalid Status Code ${response.statusCode}");
      }
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout) {
        message = "连接超时";
      } else if (e.type != DioExceptionType.unknown) {
        message = getTextBeforeNewLine(e.message ?? '未知错误');
      } else {
        message = e.toString().split("\n")[1];
      }
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    String? baseUrl,
  }) {
    return _request(Method.get, path, payload: query, baseUrl: baseUrl);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    String? baseUrl,
  }) {
    return _request(Method.post, path, payload: data, baseUrl: baseUrl);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    String? baseUrl,
  }) {
    return _request(Method.put, path, payload: data, baseUrl: baseUrl);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
    String? baseUrl,
  }) {
    return _request(Method.delete, path, payload: data, baseUrl: baseUrl);
  }
}
