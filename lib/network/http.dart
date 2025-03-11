import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/models.dart';

/// 登录
Future<LoginResponse> login(LoginPayload payload) async {
  final response = await Client.post("auth/sign-in", data: payload.toJson());
  final data = BaseResponse<LoginResponse>.fromJson(
    response,
    (data) => LoginResponse.fromJson(data),
  );
  return data.data;
}

/// 分类
Future<CategoriesResponse> fetchCategories() async {
  final response = await Client.get("categories");
  response['data']['categories'] =
      (response['data']['categories'] as List<dynamic>)
          .where((category) => category['_id'] != null)
          .toList();
  final data = BaseResponse<CategoriesResponse>.fromJson(
    response,
    (data) => CategoriesResponse.fromJson(data),
  );
  return data.data;
}

/// 根据条件获取漫画列表
Future<ComicsResponse> fetchComics(ComicsPayload payload) async {
  final response = await Client.get('categories', query: payload.toJson());
  final data = BaseResponse<ComicsResponse>.fromJson(
    response,
    (data) => ComicsResponse.fromJson(data),
  );
  return data.data;
}
