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

Doc _$DocFromJson(Map<String, dynamic> json) => Doc(
  author: json['author'] as String? ?? '',
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
  epsCount: (json['epsCount'] as num).toInt(),
  finished: json['finished'] as bool,
  id: json['id'] as String,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  pagesCount: (json['pagesCount'] as num).toInt(),
  thumb: ImageDetail.fromJson(json['thumb'] as Map<String, dynamic>),
  title: json['title'] as String,
  totalLikes: (json['totalLikes'] as num?)?.toInt(),
  totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
  uid: json['_id'] as String,
);

Map<String, dynamic> _$DocToJson(Doc instance) => <String, dynamic>{
  '_id': instance.uid,
  'title': instance.title,
  'author': instance.author,
  'totalViews': instance.totalViews,
  'totalLikes': instance.totalLikes,
  'pagesCount': instance.pagesCount,
  'epsCount': instance.epsCount,
  'finished': instance.finished,
  'categories': instance.categories,
  'thumb': instance.thumb,
  'id': instance.id,
  'likesCount': instance.likesCount,
};

Comics _$ComicsFromJson(Map<String, dynamic> json) => Comics(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
  limit: (json['limit'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$ComicsToJson(Comics instance) => <String, dynamic>{
  'docs': instance.docs,
  'total': instance.total,
  'limit': instance.limit,
  'page': instance.page,
  'pages': instance.pages,
};

ComicsResponse _$ComicsResponseFromJson(Map<String, dynamic> json) =>
    ComicsResponse(
      comics: Comics.fromJson(json['comics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComicsResponseToJson(ComicsResponse instance) =>
    <String, dynamic>{'comics': instance.comics};
