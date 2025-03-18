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
  final response = await Client.get('comics', query: payload.toJson());
  final data = BaseResponse<ComicsResponse>.fromJson(
    response,
    (data) => ComicsResponse.fromJson(data),
  );
  return data.data;
}

/// 漫画详情
Future<ComicDetailsResponse> fetchComicDetails(String id) async {
  final response = await Client.get('comics/$id');
  final data = BaseResponse<ComicDetailsResponse>.fromJson(
    response,
    (data) => ComicDetailsResponse.fromJson(data),
  );
  return data.data;
}

/// 漫画章节
Future<List<Chapter>> fetchChapters(String id) async {
  List<Chapter> chapters = [];
  final response = await Client.get('comics/$id/eps', query: {'page': 1});
  final data = BaseResponse<ChaptersResponse>.fromJson(
    response,
    (data) => ChaptersResponse.fromJson(data),
  );
  final eps = data.data.eps;
  chapters.addAll(eps.docs);
  // 并发请求快一些
  final results = await Future.wait(
    List.generate(
      eps.pages - 1,
      (index) => Client.get('comics/$id/eps', query: {'page': index + 2}),
    ),
  );
  for (var result in results) {
    final data = BaseResponse<ChaptersResponse>.fromJson(
      result,
      (data) => ChaptersResponse.fromJson(data),
    );
    chapters.addAll(data.data.eps.docs);
  }
  return chapters;
}

/// 相关漫画推荐
Future<RecommendComics> fetchComicRecommendation(String id) async {
  final response = await Client.get('comics/$id/recommendation');
  final data = BaseResponse<RecommendComics>.fromJson(
    response,
    (data) => RecommendComics.fromJson(data),
  );
  return data.data;
}

/// 点赞漫画
Future<LikeComicResponse> likeComic(String id) async {
  final response = await Client.post('comics/$id/like');
  final data = BaseResponse<LikeComicResponse>.fromJson(
    response,
    (data) => LikeComicResponse.fromJson(data),
  );
  return data.data;
}

/// 收藏漫画, 点赞和收藏返回数据结构一样
Future<LikeComicResponse> favoriteComic(String id) async {
  final response = await Client.post('comics/$id/favourite');
  final data = BaseResponse<LikeComicResponse>.fromJson(
    response,
    (data) => LikeComicResponse.fromJson(data),
  );
  return data.data;
}

/// 获取漫画评论
Future<CommentsResponse> fetchComicComments(CommentsPayload payload) async {
  final response = await Client.get(
    'comics/${payload.id}/comments',
    query: {'page': payload.page},
  );
  final data = BaseResponse<CommentsResponse>.fromJson(
    response,
    (data) => CommentsResponse.fromJson(data),
  );
  return data.data;
}
