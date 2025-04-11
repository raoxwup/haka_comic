import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

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

  String get url =>
      fileServer.contains('static')
          ? '$fileServer$path'
          : '$fileServer/static/$path';
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
class Doc {
  @JsonKey(name: '_id')
  final String uid;

  final String title;

  @JsonKey(defaultValue: '')
  final String author;

  @JsonKey(defaultValue: 0)
  final int totalViews;

  final int? totalLikes;

  final int pagesCount;

  final int epsCount;

  final bool finished;

  final List<String> categories;

  final ImageDetail thumb;

  final String? id;

  @JsonKey(defaultValue: 0)
  final int likesCount;

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
  });

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

  Map<String, dynamic> toJson() => _$DocToJson(this);
}

@JsonSerializable()
class Comics {
  final List<Doc> docs;

  final int total;

  final int limit;

  final int page;

  final int pages;

  Comics({
    required this.docs,
    required this.limit,
    required this.page,
    required this.pages,
    required this.total,
  });

  factory Comics.fromJson(Map<String, dynamic> json) => _$ComicsFromJson(json);

  Map<String, dynamic> toJson() => _$ComicsToJson(this);
}

@JsonSerializable()
class ComicsResponse {
  final Comics comics;

  ComicsResponse({required this.comics});

  factory ComicsResponse.fromJson(Map<String, dynamic> json) =>
      _$ComicsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComicsResponseToJson(this);
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

  final String author;

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

  final int limit;

  final String page;

  final int pages;

  Comments({
    required this.docs,
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

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
  final String comic;

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
class SearchComic {
  final String updated_at;

  final ImageDetail thumb;

  @JsonKey(defaultValue: '??')
  final String author;

  final String? description;

  final String? chineseTeam;

  final String created_at;

  final bool finished;

  final int? totalViews;

  final List<String> categories;

  final int? totalLikes;

  final String title;

  final List<String> tags;

  @JsonKey(name: '_id')
  final String id;

  @JsonKey(defaultValue: 0)
  final int likesCount;

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
    required this.id,
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
}

class FetchChapterImagesPayload {
  final String id;

  final int order;

  FetchChapterImagesPayload({required this.id, required this.order});
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

  final ImageDetail avatar;

  final bool isPunched;

  final String character;

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
