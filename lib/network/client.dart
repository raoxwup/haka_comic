import 'package:dio/dio.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/common.dart';

class Client {
  static final Dio _client = Dio(
    BaseOptions(
      baseUrl: host,
      responseType: ResponseType.json,
      validateStatus: (status) {
        return status == 200 || status == 400 || status == 401;
      },
    ),
  );

  static Future<Map<String, dynamic>> _request(
    Method method,
    String path, {
    Map<String, dynamic>? payload,
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
    try {
      Response response;
      switch (method) {
        case Method.get:
          response = await _client.get(path, queryParameters: payload);
          break;
        case Method.post:
          response = await _client.post(path, data: payload);
          break;
        case Method.put:
          response = await _client.put(path, data: payload);
          break;
        case Method.delete:
          response = await _client.delete(path, data: payload);
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
  }) {
    return _request(Method.get, path, payload: query);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(Method.post, path, payload: data);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(Method.put, path, payload: data);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(Method.delete, path, payload: data);
  }
}
