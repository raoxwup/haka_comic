import 'dart:convert';

import 'package:dio/dio.dart';
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
          .where((category) => category['isWeb'] != true)
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
  final url = 'comics/$id/eps';
  final response = await Client.get(url, query: {'page': 1});
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
      (index) => Client.get(url, query: {'page': index + 2}),
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
Future<ActionResponse> likeComic(String id) async {
  final response = await Client.post('comics/$id/like');
  final data = BaseResponse<ActionResponse>.fromJson(
    response,
    (data) => ActionResponse.fromJson(data),
  );
  return data.data;
}

/// 收藏漫画, 点赞和收藏返回数据结构一样
Future<ActionResponse> favoriteComic(String id) async {
  final response = await Client.post('comics/$id/favourite');
  final data = BaseResponse<ActionResponse>.fromJson(
    response,
    (data) => ActionResponse.fromJson(data),
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

/// 点赞漫画评论
Future<ActionResponse> likeComment(String id) async {
  final response = await Client.post('comments/$id/like');
  final data = BaseResponse<ActionResponse>.fromJson(
    response,
    (data) => ActionResponse.fromJson(data),
  );
  return data.data;
}

/// 发送评论
Future<void> sendComment(SendCommentPayload payload) async {
  await Client.post('comics/${payload.id}/comments', data: payload.toJson());
}

/// 获取评论子评论
Future<SubCommentsResponse> fetchSubComments(SubCommentsPayload payload) async {
  final response = await Client.get(
    'comments/${payload.id}/childrens',
    query: payload.toJson(),
  );
  final data = BaseResponse<SubCommentsResponse>.fromJson(
    response,
    (data) => SubCommentsResponse.fromJson(data),
  );
  return data.data;
}

/// 对漫画评论进行评论
Future<void> sendReply(SendCommentPayload payload) async {
  await Client.post('comments/${payload.id}', data: payload.toJson());
}

/// 搜索漫画
Future<SearchResponse> searchComics(SearchPayload payload) async {
  final response = await Client.post(
    'comics/advanced-search?page=${payload.page}',
    data: payload.toJson(),
  );
  final data = BaseResponse<SearchResponse>.fromJson(
    response,
    (data) => SearchResponse.fromJson(data),
  );
  return data.data;
}

/// 获取收藏
Future<ComicsResponse> fetchFavoriteComics(UserFavoritePayload payload) async {
  final response = await Client.get('users/favourite', query: payload.toJson());
  final data = BaseResponse<ComicsResponse>.fromJson(
    response,
    (data) => ComicsResponse.fromJson(data),
  );
  return data.data;
}

/// 获取额外推荐 这里跟其它请求不一样的host 格式也不一致
Future<List<ExtraRecommendComic>> fetchExtraRecommendComics(String id) async {
  final response = await Dio(
    BaseOptions(responseType: ResponseType.json),
  ).get<String>(
    'https://recommend.go2778.com/pic/recommend/get',
    queryParameters: {'c': id},
  );
  final json = jsonDecode(response.data ?? '[]') as List<dynamic>;
  final data = json.map((data) => ExtraRecommendComic.fromJson(data)).toList();
  return data;
}

/// 获取章节图片  一次性请求所有图片
Future<List<ChapterImage>> fetchChapterImages(
  FetchChapterImagesPayload payload,
) async {
  List<ChapterImage> images = [];
  int page = 1;
  final url = 'comics/${payload.id}/order/${payload.order}/pages';
  final response = await Client.get(url, query: {'page': page});
  final data = BaseResponse<FetchChapterImagesResponse>.fromJson(
    response,
    (data) => FetchChapterImagesResponse.fromJson(data),
  );
  images.addAll(data.data.pages.docs);
  final pages = data.data.pages;

  final requests = List.generate(
    pages.pages - 1,
    (index) => Client.get(url, query: {'page': index + 2}),
  );
  final responses = await Future.wait(requests);

  for (var response in responses) {
    final data = BaseResponse<FetchChapterImagesResponse>.fromJson(
      response,
      (data) => FetchChapterImagesResponse.fromJson(data),
    );
    images.addAll(data.data.pages.docs);
  }

  return images;
}
