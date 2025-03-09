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
