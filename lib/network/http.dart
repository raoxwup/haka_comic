import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:haka_comic/network/cache.dart';
import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/network/utils.dart';

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

/// 获取漫画分享ID
Future<int> fetchComicShareId(String id) async {
  final response = await Dio(
    BaseOptions(responseType: ResponseType.json),
  ).get<String>(
    'https://recommend.go2778.com/pic/share/set',
    queryParameters: {'c': id},
  );
  final json = jsonDecode(response.data ?? '{}');
  return json['shareId'] as int;
}

/// 根据分享ID获取漫画信息
Future<String> fetchComicIdByShareId(String shareId) async {
  final response = await Dio(
    BaseOptions(responseType: ResponseType.json),
  ).get<String>(
    'https://recommend.go2778.com/pic/share/get',
    queryParameters: {'shareId': shareId},
  );
  final json = jsonDecode(response.data ?? '{}');
  return json['cid'] as String;
}

/// 获取个人信息
Future<UserProfileResponse> fetchUserProfile() async {
  final response = await Client.get('users/profile');
  final data = BaseResponse<UserProfileResponse>.fromJson(
    response,
    (data) => UserProfileResponse.fromJson(data),
  );
  return data.data;
}

/// 获取排行榜
Future<ComicRankResponse> fetchComicRank(ComicRankPayload payload) async {
  final response = await Client.get(
    'comics/leaderboard',
    query: payload.toJson(),
  );
  final data = BaseResponse<ComicRankResponse>.fromJson(
    response,
    (data) => ComicRankResponse.fromJson(data),
  );
  return data.data;
}

/// 打卡
Future<void> punchIn() async {
  await Client.post('users/punch-in');
}

/// 获取骑士排行榜
Future<KnightRankResponse> fetchKnightRank() async {
  final response = await Client.get('comics/knight-leaderboard');
  final data = BaseResponse<KnightRankResponse>.fromJson(
    response,
    (data) => KnightRankResponse.fromJson(data),
  );
  return data.data;
}

/// 获取随机漫画
Future<RandomComicsResponse> fetchRandomComics() async {
  final response = await Client.get('comics/random');
  final data = BaseResponse<RandomComicsResponse>.fromJson(
    response,
    (data) => RandomComicsResponse.fromJson(data),
  );
  return data.data;
}

/// 获取个人评论
Future<PersonalCommentsResponse> fetchPersonalComments(int page) async {
  final response = await Client.get('users/my-comments', query: {'page': page});
  final data = BaseResponse<PersonalCommentsResponse>.fromJson(
    response,
    (data) => PersonalCommentsResponse.fromJson(data),
  );
  return data.data;
}

/// 获取热搜词
Future<HotSearchWordsResponse> fetchHotSearchWords() async {
  Map<String, dynamic> response;
  final map = Cache.get('keywords');
  if (map != null) {
    response = map;
  } else {
    response = await Client.get('keywords');
    Cache.add('keywords', response);
  }
  final data = BaseResponse<HotSearchWordsResponse>.fromJson(
    response,
    (data) => HotSearchWordsResponse.fromJson(data),
  );
  return data.data;
}

/// 更新头像
Future<void> updateAvatar(String base64) async {
  await Client.put(
    'users/avatar',
    data: {"avatar": "data:image/jpeg;base64,$base64"},
  );
}

/// 更新简介
Future<void> updateProfile(String slogan) async {
  await Client.put('users/profile', data: {"slogan": slogan});
}

/// 更新密码
Future<void> updatePassword(UpdatePasswordPayload payload) async {
  await Client.put('users/password', data: payload.toJson());
}

/// 注册
Future<void> register(RegisterPayload payload) async {
  await Client.post('auth/register', data: payload.toJson());
}

class DownloadIsolateClient {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: host,
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 10),
      validateStatus: (status) {
        return status == 200 || status == 400 || status == 401;
      },
    ),
  );

  static Future<Response> get(
    String url,
    String token, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final timestamp = getTimestamp();
    final signature = getSignature(
      '$url?page=${queryParameters?['page'] ?? 1}',
      timestamp,
      nonce,
      Method.get,
    );
    _dio.options.headers = {
      ...defaultHeaders,
      "time": timestamp,
      "signature": signature,
      "app-channel": '1',
      "image-quality": 'original',
      "authorization": token,
    };
    final response = await _dio.get(url, queryParameters: queryParameters);
    if (response.statusCode != 200) {
      throw Exception('获取章节图片失败');
    }
    return response;
  }
}

/// 获取章节图片Isolate版
Future<List<ChapterImage>> fetchChapterImagesIsolate(
  FetchChapterImagesPayload payload,
  String token,
) async {
  List<ChapterImage> images = [];
  int page = 1;
  final url = 'comics/${payload.id}/order/${payload.order}/pages';
  final response = await DownloadIsolateClient.get(
    url,
    token,
    queryParameters: {'page': page},
  );

  final data = BaseResponse<FetchChapterImagesResponse>.fromJson(
    response.data,
    (data) => FetchChapterImagesResponse.fromJson(data),
  );
  images.addAll(data.data.pages.docs);
  final pages = data.data.pages;

  final requests = List.generate(
    pages.pages - 1,
    (index) => DownloadIsolateClient.get(
      url,
      token,
      queryParameters: {'page': index + 2},
    ),
  );
  final responses = await Future.wait(requests);

  for (var response in responses) {
    final data = BaseResponse<FetchChapterImagesResponse>.fromJson(
      response.data,
      (data) => FetchChapterImagesResponse.fromJson(data),
    );
    images.addAll(data.data.pages.docs);
  }

  return images;
}

///用于检查是否有新的release发布
Future<Response<dynamic>> checkUpdate() async {
  // 访问地址 e.g. https://github.com/raoxwup/haka_comic/releases/tag/1.0.0-beta1
  final dio = Dio(BaseOptions(responseType: ResponseType.json));
  final response = await dio.get(
    'https://api.github.com/repos/raoxwup/haka_comic/releases/latest',
  );
  return response;
}
