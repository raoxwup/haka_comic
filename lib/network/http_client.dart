// import 'package:haka_comic/network/utils.dart';
// import 'package:haka_comic/router/app_router.dart';
// import 'package:haka_comic/utils/common.dart';
// import 'package:rhttp/rhttp.dart';

// class Client {
//   static late final RhttpClient _client;
//   static late final String ip;
//   static CancelToken _cancelToken = CancelToken();

//   /// 初始化客户端，绑定 IP 到域名
//   static Future<void> initialize([
//     String address = 'picaapi.picacomic.com',
//   ]) async {
//     _client = await RhttpClient.create(
//       settings: ClientSettings(
//         baseUrl: host,
//         timeoutSettings: const TimeoutSettings(
//           timeout: Duration(seconds: 10),
//           connectTimeout: Duration(seconds: 5),
//         ),
//         dnsSettings: DnsSettings.static(
//           overrides: {
//             'picaapi.picacomic.com': [address],
//           },
//         ),
//         throwOnStatusCode: false,
//       ),
//     );
//     ip = address;
//   }

//   /// 通用请求方法
//   static Future<Map<String, dynamic>> _request(
//     Method method,
//     String path, {
//     Map<String, dynamic>? payload,
//   }) async {
//     try {
//       // 处理 query 参数（仅 GET 有效）
//       final queryParams =
//           method == Method.get ? _stringifyPayload(payload) : null;

//       // 生成 headers
//       final map = _buildHeaders(path, method, queryParams);
//       final headers = HttpHeaders.list(
//         map.entries.map((e) => (e.key, e.value)).toList(),
//       );

//       // 构造请求体
//       final body =
//           (method == Method.get || payload == null)
//               ? null
//               : HttpBody.json(payload);

//       // 发送请求
//       final response = await _sendRequest(
//         method: method,
//         path: path,
//         query: queryParams,
//         body: body,
//         headers: headers,
//       );

//       return _handleResponse(response);
//     } on RhttpTimeoutException {
//       throw Exception("连接超时");
//     } on RhttpUnknownException catch (e) {
//       throw Exception(getTextBeforeNewLine(e.message));
//     } on RhttpException {
//       throw Exception("未知错误");
//     }
//   }

//   /// GET 请求
//   static Future<Map<String, dynamic>> get(
//     String path, {
//     Map<String, dynamic>? query,
//   }) => _request(Method.get, path, payload: query);

//   /// POST 请求
//   static Future<Map<String, dynamic>> post(
//     String path, {
//     Map<String, dynamic>? data,
//   }) => _request(Method.post, path, payload: data);

//   /// PUT 请求
//   static Future<Map<String, dynamic>> put(
//     String path, {
//     Map<String, dynamic>? data,
//   }) => _request(Method.put, path, payload: data);

//   /// DELETE 请求
//   static Future<Map<String, dynamic>> delete(
//     String path, {
//     Map<String, dynamic>? data,
//   }) => _request(Method.delete, path, payload: data);

//   /// 将 payload 转换成字符串 map（用于 query）
//   static Map<String, String>? _stringifyPayload(Map<String, dynamic>? payload) {
//     if (payload == null) return null;
//     return payload.map((k, v) => MapEntry(k, v.toString()));
//   }

//   /// 构建请求头
//   static Map<String, String> _buildHeaders(
//     String path,
//     Method method,
//     Map<String, String>? queryParams,
//   ) {
//     final requestPath =
//         (method == Method.get && queryParams != null && queryParams.isNotEmpty)
//             ? '$path?${Uri(queryParameters: queryParams).query}'
//             : path;

//     return getHeaders(requestPath, method);
//   }

//   /// 发送请求
//   static Future<HttpTextResponse> _sendRequest({
//     required Method method,
//     required String path,
//     Map<String, String>? query,
//     HttpBody? body,
//     HttpHeaders? headers,
//   }) {
//     switch (method) {
//       case Method.get:
//         return _client.get(
//           path,
//           query: query,
//           headers: headers,
//           cancelToken: _cancelToken,
//         );
//       case Method.post:
//         return _client.post(
//           path,
//           body: body,
//           headers: headers,
//           cancelToken: _cancelToken,
//         );
//       case Method.put:
//         return _client.put(
//           path,
//           body: body,
//           headers: headers,
//           cancelToken: _cancelToken,
//         );
//       case Method.delete:
//         return _client.delete(
//           path,
//           body: body,
//           headers: headers,
//           cancelToken: _cancelToken,
//         );
//     }
//   }

//   /// 处理响应
//   static Map<String, dynamic> _handleResponse(HttpTextResponse response) {
//     switch (response.statusCode) {
//       case 200:
//         return response.bodyToJson;
//       case 400:
//         final data = response.bodyToJson;
//         throw data['message'];
//       case 401:
//         _cancelToken.cancel();
//         _cancelToken = CancelToken();
//         logout();
//         throw "登录失效";
//       default:
//         throw Exception("Invalid Status Code ${response.statusCode}");
//     }
//   }
// }
