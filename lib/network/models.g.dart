// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(token: json['token'] as String);

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{'token': instance.token};

ImageDetail _$ImageDetailFromJson(Map<String, dynamic> json) => ImageDetail(
  fileServer: json['fileServer'] as String,
  path: json['path'] as String,
  originalName: json['originalName'] as String,
);

Map<String, dynamic> _$ImageDetailToJson(ImageDetail instance) =>
    <String, dynamic>{
      'fileServer': instance.fileServer,
      'path': instance.path,
      'originalName': instance.originalName,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['_id'] as String,
  thumb: ImageDetail.fromJson(json['thumb'] as Map<String, dynamic>),
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  '_id': instance.id,
  'thumb': instance.thumb,
  'title': instance.title,
  'description': instance.description,
};

CategoriesResponse _$CategoriesResponseFromJson(Map<String, dynamic> json) =>
    CategoriesResponse(
      categories:
          (json['categories'] as List<dynamic>)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$CategoriesResponseToJson(CategoriesResponse instance) =>
    <String, dynamic>{'categories': instance.categories};
