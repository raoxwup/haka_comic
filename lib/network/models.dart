import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';

part 'models.g.dart';
part 'models.freezed.dart';

class BaseResponse<T> {
  final int code;
  final String message;
  final T data;

  BaseResponse({required this.code, required this.message, required this.data});

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return BaseResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      data: fromJsonT(json['data']),
    );
  }

  Map<String, dynamic> toJson(dynamic Function(T) toJsonT) {
    return {'code': code, 'message': message, 'data': toJsonT(data)};
  }
}

class LoginPayload {
  String email;
  String password;
  LoginPayload({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

@JsonSerializable()
class LoginResponse {
  final String token;
  LoginResponse({required this.token});
  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class ImageDetail {
  final String fileServer;
  final String path;
  final String originalName;

  ImageDetail({
    required this.fileServer,
    required this.path,
    required this.originalName,
  });

  factory ImageDetail.fromJson(Map<String, dynamic> json) =>
      _$ImageDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ImageDetailToJson(this);

  // 直连
  String get directUrl => fileServer.contains('static')
      ? '$fileServer$path'
      : '$fileServer/static/$path';

  // web代理
  String get proxyUrl => directUrl.replaceFirst('picacomic', 'go2778');

  String get url => AppConf().api == Api.app ? directUrl : proxyUrl;

  String getIsolateDownloadUrl(Api api) {
    return api == Api.app ? directUrl : proxyUrl;
  }
}

@JsonSerializable()
class Category {
  @JsonKey(name: '_id')
  final String? id;

  final ImageDetail thumb;

  final String title;

  @JsonKey(defaultValue: '')
  final String description;

  final bool? isWeb;

  final bool? active;

  final String? link;

  Category({
    this.id,
    required this.thumb,
    required this.title,
    required this.description,
    this.isWeb,
    this.active,
    this.link,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class CategoriesResponse {
  final List<Category> categories;

  CategoriesResponse({required this.categories});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriesResponseToJson(this);
}

// 漫画排序方式
enum ComicSortType {
  /// 新到旧
  dd,

  /// 旧到新
  da,

  /// 最多喜欢
  ld,

  /// 最多观看
  vd,
}

class ComicsPayload {
  /// 分页
  final int? page;

  /// 分类
  final String? c;

  /// 排序
  final ComicSortType? s;

  /// Tag
  final String? t;

  /// 作者
  final String? a;

  /// 汉化组
  final String? ct;

  /// 上传者
  final String? ca;

  ComicsPayload({this.page, this.c, this.s, this.t, this.a, this.ca, this.ct});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (page != null) json['page'] = page;
    if (c != null) json['c'] = c!;
    if (s != null) json['s'] = s!.name;
    if (a != null) json['a'] = a!;
    if (ca != null) json['ca'] = ca!;
    if (ct != null) json['ct'] = ct!;
    if (t != null) json['t'] = t!;
    return json;
  }
}

@JsonSerializable()
class Doc extends ComicBase {
  @override
  @JsonKey(name: '_id')
  final String uid;

  @override
  final String title;

  @override
  @JsonKey(defaultValue: '')
  final String author;

  @override
  @JsonKey(defaultValue: 0)
  final int totalViews;

  @override
  final int? totalLikes;

  final int pagesCount;

  final int epsCount;

  @override
  final bool finished;

  @override
  final List<String> categories;

  @override
  final ImageDetail thumb;

  final String? id;

  @override
  @JsonKey(defaultValue: 0)
  final int likesCount;

  @override
  @JsonKey(defaultValue: [])
  final List<String> tags;

  Doc({
    required this.author,
    required this.categories,
    required this.epsCount,
    required this.finished,
    this.id,
    required this.likesCount,
    required this.pagesCount,
    required this.thumb,
    required this.title,
    this.totalLikes,
    required this.totalViews,
    required this.uid,
    required this.tags,
  });

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

  Map<String, dynamic> toJson() => _$DocToJson(this);
}

@freezed
abstract class Comics with _$Comics {
  const factory Comics({
    required List<Doc> docs,
    required int limit,
    required int page,
    required int pages,
    required int total,
  }) = _Comics;

  factory Comics.fromJson(Map<String, dynamic> json) => _$ComicsFromJson(json);
}

@freezed
abstract class ComicsResponse with _$ComicsResponse {
  const factory ComicsResponse({required Comics comics}) = _ComicsResponse;

  factory ComicsResponse.fromJson(Map<String, dynamic> json) =>
      _$ComicsResponseFromJson(json);
}

@JsonSerializable()
class Creator {
  @JsonKey(name: '_id')
  final String id;

  final String gender;

  final String name;

  @JsonKey(defaultValue: 0)
  final int exp;

  final int level;

  final String role;

  final ImageDetail? avatar;

  final List<String> characters;

  @JsonKey(defaultValue: '')
  final String title;

  final String? slogan;

  Creator({
    required this.id,
    this.avatar,
    required this.characters,
    required this.exp,
    required this.gender,
    required this.level,
    required this.name,
    required this.role,
    required this.title,
    this.slogan,
  });

  factory Creator.fromJson(Map<String, dynamic> json) =>
      _$CreatorFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorToJson(this);
}

@JsonSerializable()
class Comic {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: '_creator')
  final Creator creator;

  final String title;

  @JsonKey(defaultValue: '')
  final String description;

  final ImageDetail thumb;

  final String? author;

  final List<String> categories;

  @JsonKey(defaultValue: '')
  final String chineseTeam;

  final List<String> tags;

  final int pagesCount;

  final int epsCount;

  final bool finished;

  final String updated_at;

  final String created_at;

  final bool allowDownload;

  final bool allowComment;

  final int totalLikes;

  final int totalViews;

  final int? totalComments;

  final int viewsCount;

  final int likesCount;

  @JsonKey(defaultValue: 0)
  final int commentsCount;

  // 好多单词拼写错误
  final bool isFavourite;

  final bool isLiked;

  Comic({
    required this.author,
    required this.categories,
    required this.chineseTeam,
    required this.created_at,
    required this.description,
    required this.epsCount,
    required this.finished,
    required this.id,
    required this.isFavourite,
    required this.isLiked,
    required this.likesCount,
    required this.pagesCount,
    required this.tags,
    required this.thumb,
    required this.title,
    required this.totalLikes,
    required this.totalViews,
    required this.totalComments,
    required this.updated_at,
    required this.viewsCount,
    required this.creator,
    required this.allowDownload,
    required this.allowComment,
    required this.commentsCount,
  });

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);

  Map<String, dynamic> toJson() => _$ComicToJson(this);
}

@JsonSerializable()
class ComicDetailsResponse {
  final Comic comic;

  ComicDetailsResponse({required this.comic});

  factory ComicDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$ComicDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComicDetailsResponseToJson(this);
}

@JsonSerializable()
class Chapter {
  @JsonKey(name: '_id')
  final String uid;

  final String title;

  final int order;

  final String updated_at;

  final String id;

  Chapter({
    required this.uid,
    required this.title,
    required this.order,
    required this.updated_at,
    required this.id,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterToJson(this);
}

@JsonSerializable()
class Chapters {
  final List<Chapter> docs;

  final int total;

  final int limit;

  final int page;

  final int pages;

  Chapters({
    required this.docs,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  factory Chapters.fromJson(Map<String, dynamic> json) =>
      _$ChaptersFromJson(json);

  Map<String, dynamic> toJson() => _$ChaptersToJson(this);
}

@JsonSerializable()
class ChaptersResponse {
  final Chapters eps;

  ChaptersResponse({required this.eps});

  factory ChaptersResponse.fromJson(Map<String, dynamic> json) =>
      _$ChaptersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChaptersResponseToJson(this);
}

@JsonSerializable()
class RecommendComic {
  @JsonKey(name: '_id')
  final String id;

  final String title;

  @JsonKey(defaultValue: '')
  final String author;

  final ImageDetail thumb;

  @JsonKey(defaultValue: 0)
  final int pagesCount;

  @JsonKey(defaultValue: 0)
  final int epsCount;

  final bool finished;

  final List<String> categories;

  @JsonKey(defaultValue: 0)
  final int likesCount;

  RecommendComic({
    required this.id,
    required this.title,
    required this.author,
    required this.thumb,
    required this.pagesCount,
    required this.epsCount,
    required this.finished,
    required this.categories,
    required this.likesCount,
  });

  factory RecommendComic.fromJson(Map<String, dynamic> json) =>
      _$RecommendComicFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendComicToJson(this);
}

@JsonSerializable()
class RecommendComics {
  final List<RecommendComic> comics;

  RecommendComics({required this.comics});

  factory RecommendComics.fromJson(Map<String, dynamic> json) =>
      _$RecommendComicsFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendComicsToJson(this);
}

@JsonSerializable()
class ActionResponse {
  final String action;

  ActionResponse({required this.action});

  factory ActionResponse.fromJson(Map<String, dynamic> json) =>
      _$ActionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActionResponseToJson(this);
}

class CommentsPayload {
  final String id;

  final int page;

  CommentsPayload({required this.id, required this.page});
}

@JsonSerializable()
class Comment {
  @JsonKey(name: '_id')
  final String uid;

  final String content;

  @JsonKey(name: '_user')
  final Creator user;

  @JsonKey(name: '_comic')
  final String comic;

  final int? totalComments;

  final bool isTop;

  final bool hide;

  final String created_at;

  final String id;

  @JsonKey(defaultValue: 0)
  final int likesCount;

  final int commentsCount;

  final bool isLiked;

  Comment({
    required this.uid,
    required this.content,
    required this.user,
    required this.comic,
    required this.totalComments,
    required this.isTop,
    required this.hide,
    required this.created_at,
    required this.id,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);
}

@JsonSerializable()
class Comments {
  final List<Comment> docs;

  final int total;

  @JsonKey(defaultValue: 20)
  final int limit;

  /// 极端情况下又返回的不是字符串....
  @JsonKey(fromJson: _pageFormat)
  final String page;

  final int pages;

  Comments({
    required this.docs,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  static String _pageFormat(dynamic value) => value.toString();

  factory Comments.fromJson(Map<String, dynamic> json) =>
      _$CommentsFromJson(json);

  Map<String, dynamic> toJson() => _$CommentsToJson(this);
}

@JsonSerializable()
class CommentsResponse {
  final Comments comments;

  CommentsResponse({required this.comments});

  factory CommentsResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommentsResponseToJson(this);
}

class SendCommentPayload {
  final String id;

  final String content;

  SendCommentPayload({required this.id, required this.content});

  Map<String, dynamic> toJson() => {'content': content};
}

@JsonSerializable()
class SubComment {
  @JsonKey(name: '_id')
  final String uid;

  final String content;

  @JsonKey(name: '_user')
  final Creator user;

  final String created_at;

  final bool hide;

  final String id;

  final bool isLiked;

  final bool isTop;

  final int likesCount;

  final int totalComments;

  @JsonKey(name: '_comic')
  final String? comic;

  @JsonKey(name: '_game')
  final String? game;

  @JsonKey(name: '_parent')
  final String parent;

  SubComment({
    required this.uid,
    required this.content,
    required this.user,
    required this.created_at,
    required this.hide,
    required this.id,
    required this.isLiked,
    required this.isTop,
    required this.likesCount,
    required this.totalComments,
    required this.comic,
    required this.parent,
    required this.game,
  });

  factory SubComment.fromJson(Map<String, dynamic> json) =>
      _$SubCommentFromJson(json);

  Map<String, dynamic> toJson() => _$SubCommentToJson(this);
}

@JsonSerializable()
class SubComments {
  final List<SubComment> docs;

  final int total;

  final int limit;

  final String page;

  final int pages;

  SubComments({
    required this.docs,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  factory SubComments.fromJson(Map<String, dynamic> json) =>
      _$SubCommentsFromJson(json);

  Map<String, dynamic> toJson() => _$SubCommentsToJson(this);
}

@JsonSerializable()
class SubCommentsResponse {
  final SubComments comments;

  SubCommentsResponse({required this.comments});

  factory SubCommentsResponse.fromJson(Map<String, dynamic> json) =>
      _$SubCommentsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubCommentsResponseToJson(this);
}

class SubCommentsPayload {
  final String id;

  final int page;

  SubCommentsPayload({required this.id, required this.page});

  Map<String, dynamic> toJson() => {'page': page};
}

class SearchPayload {
  final String keyword;

  final int page;

  final ComicSortType sort;

  SearchPayload({
    required this.keyword,
    required this.page,
    required this.sort,
  });

  Map<String, dynamic> toJson() => {'keyword': keyword, 'sort': sort.name};
}

@JsonSerializable()
class SearchComic extends ComicBase {
  final String updated_at;

  @override
  final ImageDetail thumb;

  @override
  @JsonKey(defaultValue: '??')
  final String author;

  final String? description;

  final String? chineseTeam;

  final String created_at;

  @override
  final bool finished;

  @override
  final int? totalViews;

  @override
  final List<String> categories;

  @override
  @JsonKey(fromJson: _totalLikesFromJson)
  final int? totalLikes;

  @override
  final String title;

  @override
  final List<String> tags;

  @override
  @JsonKey(name: '_id')
  final String uid;

  // 这个字段还有返回String的 ......
  @override
  @JsonKey(defaultValue: 0, fromJson: _likesCountFromJson)
  final int likesCount;

  static int _likesCountFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _totalLikesFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  SearchComic({
    required this.updated_at,
    required this.thumb,
    required this.author,
    required this.description,
    required this.chineseTeam,
    required this.created_at,
    required this.finished,
    required this.totalViews,
    required this.categories,
    required this.totalLikes,
    required this.title,
    required this.tags,
    required this.uid,
    required this.likesCount,
  });

  factory SearchComic.fromJson(Map<String, dynamic> json) =>
      _$SearchComicFromJson(json);

  Map<String, dynamic> toJson() => _$SearchComicToJson(this);
}

@JsonSerializable()
class SearchComics {
  final List<SearchComic> docs;

  final int total;

  final int limit;

  final int page;

  final int pages;

  SearchComics({
    required this.docs,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  factory SearchComics.fromJson(Map<String, dynamic> json) =>
      _$SearchComicsFromJson(json);

  Map<String, dynamic> toJson() => _$SearchComicsToJson(this);
}

@JsonSerializable()
class SearchResponse {
  final SearchComics comics;

  SearchResponse({required this.comics});

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResponseToJson(this);
}

class UserFavoritePayload {
  final int page;

  final ComicSortType sort;

  UserFavoritePayload({required this.page, required this.sort});

  Map<String, dynamic> toJson() => {'page': page, 's': sort.name};
}

class ExtraRecommendComic {
  final String id;

  final String title;

  final String pic;

  ExtraRecommendComic({
    required this.id,
    required this.title,
    required this.pic,
  });

  factory ExtraRecommendComic.fromJson(Map<String, dynamic> json) =>
      ExtraRecommendComic(
        id: json['id'],
        title: json['title'],
        pic: json['pic'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'pic': pic};

  String get url =>
      AppConf().api == Api.app ? pic : pic.replaceFirst('picacomic', 'go2778');
}

class FetchChapterImagesPayload {
  final String id;
  final int order;

  const FetchChapterImagesPayload({required this.id, required this.order});
}

@JsonSerializable()
class ChapterImage {
  @JsonKey(name: '_id')
  final String uid;

  final String? id;

  final ImageDetail media;

  ChapterImage({required this.uid, required this.id, required this.media});

  factory ChapterImage.fromJson(Map<String, dynamic> json) =>
      _$ChapterImageFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterImageToJson(this);
}

@JsonSerializable()
class ChaptersImages {
  final List<ChapterImage> docs;

  final int total;

  final int limit;

  final int page;

  final int pages;

  ChaptersImages({
    required this.docs,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  factory ChaptersImages.fromJson(Map<String, dynamic> json) =>
      _$ChaptersImagesFromJson(json);

  Map<String, dynamic> toJson() => _$ChaptersImagesToJson(this);
}

@JsonSerializable()
class ChapterEpisode {
  @JsonKey(name: '_id')
  final String id;

  final String title;

  ChapterEpisode({required this.id, required this.title});

  factory ChapterEpisode.fromJson(Map<String, dynamic> json) =>
      _$ChapterEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterEpisodeToJson(this);
}

@JsonSerializable()
class FetchChapterImagesResponse {
  final ChaptersImages pages;

  final ChapterEpisode ep;

  FetchChapterImagesResponse({required this.pages, required this.ep});

  factory FetchChapterImagesResponse.fromJson(Map<String, dynamic> json) =>
      _$FetchChapterImagesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FetchChapterImagesResponseToJson(this);
}

@JsonSerializable()
class HistoryDoc extends Doc {
  final String updatedAt;
  final String createdAt;

  HistoryDoc({
    required super.id,
    required super.title,
    required super.author,
    required super.totalViews,
    required super.totalLikes,
    required super.pagesCount,
    required super.epsCount,
    required super.finished,
    required super.categories,
    required super.thumb,
    required super.likesCount,
    required super.uid,
    required super.tags,
    required this.updatedAt,
    required this.createdAt,
  });

  factory HistoryDoc.fromJson(Map<String, dynamic> json) =>
      _$HistoryDocFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HistoryDocToJson(this);
}

@JsonSerializable()
class UserProfileResponse {
  final User user;

  UserProfileResponse({required this.user});

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileResponseToJson(this);
}

@JsonSerializable()
class User {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(defaultValue: '')
  final String birthday;

  @JsonKey(defaultValue: '')
  final String email;

  @JsonKey(defaultValue: 'm')
  final String gender;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String slogan;

  @JsonKey(defaultValue: '萌新')
  final String title;

  @JsonKey(defaultValue: false)
  final bool verified;

  @JsonKey(defaultValue: 0)
  final int exp;

  @JsonKey(defaultValue: 0)
  final int level;

  @JsonKey(defaultValue: [])
  final List<String> characters;

  @JsonKey(defaultValue: "")
  final String created_at;

  final ImageDetail? avatar;

  @JsonKey(defaultValue: false)
  final bool isPunched;

  @JsonKey(defaultValue: '')
  final String character;

  @JsonKey(defaultValue: 0)
  final int comicsUploaded;

  User({
    required this.id,
    required this.birthday,
    required this.email,
    required this.gender,
    required this.name,
    required this.slogan,
    required this.title,
    required this.verified,
    required this.exp,
    required this.level,
    required this.characters,
    required this.created_at,
    required this.avatar,
    required this.isPunched,
    required this.character,
    required this.comicsUploaded,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

enum ComicRankType {
  /// 按日排行
  H24,

  /// 按周排行
  D7,

  /// 按月排行
  D30,
}

class ComicRankPayload {
  final ComicRankType type;

  ComicRankPayload({required this.type});

  Map<String, dynamic> toJson() => {'tt': type.name, 'ct': 'VC'};
}

@JsonSerializable()
class ComicRankResponse {
  final List<Doc> comics;

  ComicRankResponse({required this.comics});

  factory ComicRankResponse.fromJson(Map<String, dynamic> json) =>
      _$ComicRankResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComicRankResponseToJson(this);
}

@JsonSerializable()
class KnightRankResponse {
  final List<User> users;

  KnightRankResponse({required this.users});

  factory KnightRankResponse.fromJson(Map<String, dynamic> json) =>
      _$KnightRankResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KnightRankResponseToJson(this);
}

@JsonSerializable()
class RandomComicsResponse {
  final List<Doc> comics;

  RandomComicsResponse({required this.comics});

  factory RandomComicsResponse.fromJson(Map<String, dynamic> json) =>
      _$RandomComicsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RandomComicsResponseToJson(this);
}

@JsonSerializable()
class Source {
  final String title;

  @JsonKey(name: '_id')
  final String id;

  Source({required this.title, required this.id});

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);

  Map<String, dynamic> toJson() => _$SourceToJson(this);
}

@JsonSerializable()
class PersonalComment {
  @JsonKey(name: '_id')
  final String uid;

  final String content;

  @JsonKey(name: '_comic')
  final Source? comic;

  @JsonKey(name: '_game')
  final Source? game;

  final int? totalComments;

  @JsonKey(defaultValue: false)
  final bool hide;

  final String created_at;

  final String? id;

  final int likesCount;

  @JsonKey(defaultValue: 0)
  final int commentsCount;

  final bool isLiked;

  PersonalComment({
    required this.uid,
    required this.content,
    required this.comic,
    required this.game,
    required this.totalComments,
    required this.hide,
    required this.created_at,
    required this.id,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
  });

  factory PersonalComment.fromJson(Map<String, dynamic> json) =>
      _$PersonalCommentFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalCommentToJson(this);
}

@JsonSerializable()
class PersonalComments {
  final List<PersonalComment> docs;

  final int pages;

  final int total;

  final int limit;

  final String page;

  PersonalComments({
    required this.docs,
    required this.pages,
    required this.total,
    required this.limit,
    required this.page,
  });

  factory PersonalComments.fromJson(Map<String, dynamic> json) =>
      _$PersonalCommentsFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalCommentsToJson(this);
}

@JsonSerializable()
class PersonalCommentsResponse {
  final PersonalComments comments;

  PersonalCommentsResponse({required this.comments});

  factory PersonalCommentsResponse.fromJson(Map<String, dynamic> json) =>
      _$PersonalCommentsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalCommentsResponseToJson(this);
}

@JsonSerializable()
class HotSearchWordsResponse {
  final List<String> keywords;

  HotSearchWordsResponse({required this.keywords});

  factory HotSearchWordsResponse.fromJson(Map<String, dynamic> json) =>
      _$HotSearchWordsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HotSearchWordsResponseToJson(this);
}

class UpdatePasswordPayload {
  final String oldPassword;
  final String newPassword;

  UpdatePasswordPayload({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() => {
    'new_password': newPassword,
    'old_password': oldPassword,
  };
}

class RegisterPayload {
  final String birthday;
  final String email;
  final String gender;
  final String name;
  final String password;

  RegisterPayload({
    required this.birthday,
    required this.email,
    required this.gender,
    required this.name,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'birthday': birthday,
    'email': email,
    'gender': gender,
    'name': name,
    'password': password,
    'question1': '1',
    'question2': '2',
    'question3': '3',
    'answer1': '4',
    'answer2': '5',
    'answer3': '6',
  };
}

@JsonSerializable()
class NotificationsResponse {
  final NotificationsData notifications;

  NotificationsResponse({required this.notifications});

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationsResponseToJson(this);
}

@JsonSerializable()
class NotificationsData {
  final List<NotificationDoc> docs;
  final int limit;
  final int page;
  final int pages;
  final int total;

  NotificationsData({
    required this.docs,
    required this.limit,
    required this.page,
    required this.pages,
    required this.total,
  });

  factory NotificationsData.fromJson(Map<String, dynamic> json) =>
      _$NotificationsDataFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationsDataToJson(this);
}

@JsonSerializable()
class NotificationDoc {
  final String content;
  final ImageDetail? cover;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: '_id')
  final String uid;

  final String id;

  @JsonKey(name: '_redirectId')
  final String redirectId;

  final String redirectType;

  @JsonKey(name: '_sender')
  final User sender;

  final bool system;
  final String title;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @JsonKey(name: '_user')
  final String user;

  NotificationDoc({
    required this.content,
    required this.cover,
    required this.createdAt,
    required this.uid,
    required this.id,
    required this.redirectId,
    required this.redirectType,
    required this.sender,
    required this.system,
    required this.title,
    required this.updatedAt,
    required this.user,
  });

  factory NotificationDoc.fromJson(Map<String, dynamic> json) =>
      _$NotificationDocFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationDocToJson(this);
}

@JsonSerializable()
class InitResponse {
  final String status;

  final List<String> addresses;

  final String waka;

  final String adKeyword;

  InitResponse({
    required this.status,
    required this.addresses,
    required this.waka,
    required this.adKeyword,
  });

  factory InitResponse.fromJson(Map<String, dynamic> json) =>
      _$InitResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InitResponseToJson(this);
}

abstract class ComicBase {
  String get uid;
  String get title;
  String get author;
  List<String> get categories;
  List<String> get tags;
  ImageDetail get thumb;
  bool get finished;
  int? get totalViews;
  int? get totalLikes;
  int get likesCount;
}
