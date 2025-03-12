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
  final String id;

  final ImageDetail thumb;

  final String title;

  @JsonKey(defaultValue: '')
  final String description;

  Category({
    required this.id,
    required this.thumb,
    required this.title,
    required this.description,
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

  final String id;

  @JsonKey(defaultValue: 0)
  final int likesCount;

  Doc({
    required this.author,
    required this.categories,
    required this.epsCount,
    required this.finished,
    required this.id,
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
