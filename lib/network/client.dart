import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/log.dart';

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

  static Future<String> _request(
    Method method,
    String path, {
    Map<String, dynamic>? payload,
  }) async {
    final headers = getHeaders(path, Method.get);
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
          var jsonResponse = jsonDecode(response.data);
          throw Exception(jsonResponse['message']);
        case 401:
          goLogin();
          throw Exception('登录失效');
        default:
          throw Exception("Invalid Status Code ${response.statusCode}");
      }
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout) {
        message = "连接超时";
      } else if (e.type != DioExceptionType.unknown) {
        message = e.message!;
      } else {
        message = e.toString().split("\n")[1];
      }
      throw Exception(message);
    } catch (e) {
      Log.error("GET $path failed", e);
      rethrow;
    }
  }

  static Future<String> get(String path, {Map<String, dynamic>? query}) {
    return _request(Method.get, path, payload: query);
  }

  static Future<String> post(String path, {Map<String, dynamic>? data}) {
    return _request(Method.post, path, payload: data);
  }

  static Future<String> put(String path, {Map<String, dynamic>? data}) {
    return _request(Method.put, path, payload: data);
  }

  static Future<String> delete(String path, {Map<String, dynamic>? data}) {
    return _request(Method.delete, path, payload: data);
  }
}
