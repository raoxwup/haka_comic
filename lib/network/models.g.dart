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
  id: json['id'] as String?,
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

Creator _$CreatorFromJson(Map<String, dynamic> json) => Creator(
  id: json['_id'] as String,
  avatar:
      json['avatar'] == null
          ? null
          : ImageDetail.fromJson(json['avatar'] as Map<String, dynamic>),
  characters:
      (json['characters'] as List<dynamic>).map((e) => e as String).toList(),
  exp: (json['exp'] as num?)?.toInt() ?? 0,
  gender: json['gender'] as String,
  level: (json['level'] as num).toInt(),
  name: json['name'] as String,
  role: json['role'] as String,
  title: json['title'] as String? ?? '',
  slogan: json['slogan'] as String?,
);

Map<String, dynamic> _$CreatorToJson(Creator instance) => <String, dynamic>{
  '_id': instance.id,
  'gender': instance.gender,
  'name': instance.name,
  'exp': instance.exp,
  'level': instance.level,
  'role': instance.role,
  'avatar': instance.avatar,
  'characters': instance.characters,
  'title': instance.title,
  'slogan': instance.slogan,
};

Comic _$ComicFromJson(Map<String, dynamic> json) => Comic(
  author: json['author'] as String,
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
  chineseTeam: json['chineseTeam'] as String? ?? '',
  created_at: json['created_at'] as String,
  description: json['description'] as String? ?? '',
  epsCount: (json['epsCount'] as num).toInt(),
  finished: json['finished'] as bool,
  id: json['_id'] as String,
  isFavourite: json['isFavourite'] as bool,
  isLiked: json['isLiked'] as bool,
  likesCount: (json['likesCount'] as num).toInt(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  thumb: ImageDetail.fromJson(json['thumb'] as Map<String, dynamic>),
  title: json['title'] as String,
  totalLikes: (json['totalLikes'] as num).toInt(),
  totalViews: (json['totalViews'] as num).toInt(),
  totalComments: (json['totalComments'] as num?)?.toInt(),
  updated_at: json['updated_at'] as String,
  viewsCount: (json['viewsCount'] as num).toInt(),
  creator: Creator.fromJson(json['_creator'] as Map<String, dynamic>),
  allowDownload: json['allowDownload'] as bool,
  allowComment: json['allowComment'] as bool,
  commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ComicToJson(Comic instance) => <String, dynamic>{
  '_id': instance.id,
  '_creator': instance.creator,
  'title': instance.title,
  'description': instance.description,
  'thumb': instance.thumb,
  'author': instance.author,
  'categories': instance.categories,
  'chineseTeam': instance.chineseTeam,
  'tags': instance.tags,
  'pagesCount': instance.pagesCount,
  'epsCount': instance.epsCount,
  'finished': instance.finished,
  'updated_at': instance.updated_at,
  'created_at': instance.created_at,
  'allowDownload': instance.allowDownload,
  'allowComment': instance.allowComment,
  'totalLikes': instance.totalLikes,
  'totalViews': instance.totalViews,
  'totalComments': instance.totalComments,
  'viewsCount': instance.viewsCount,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'isFavourite': instance.isFavourite,
  'isLiked': instance.isLiked,
};

ComicDetailsResponse _$ComicDetailsResponseFromJson(
  Map<String, dynamic> json,
) => ComicDetailsResponse(
  comic: Comic.fromJson(json['comic'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ComicDetailsResponseToJson(
  ComicDetailsResponse instance,
) => <String, dynamic>{'comic': instance.comic};

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  uid: json['_id'] as String,
  title: json['title'] as String,
  order: (json['order'] as num).toInt(),
  updated_at: json['updated_at'] as String,
  id: json['id'] as String,
);

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
  '_id': instance.uid,
  'title': instance.title,
  'order': instance.order,
  'updated_at': instance.updated_at,
  'id': instance.id,
};

Chapters _$ChaptersFromJson(Map<String, dynamic> json) => Chapters(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$ChaptersToJson(Chapters instance) => <String, dynamic>{
  'docs': instance.docs,
  'total': instance.total,
  'limit': instance.limit,
  'page': instance.page,
  'pages': instance.pages,
};

ChaptersResponse _$ChaptersResponseFromJson(Map<String, dynamic> json) =>
    ChaptersResponse(
      eps: Chapters.fromJson(json['eps'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChaptersResponseToJson(ChaptersResponse instance) =>
    <String, dynamic>{'eps': instance.eps};

RecommendComic _$RecommendComicFromJson(Map<String, dynamic> json) =>
    RecommendComic(
      id: json['_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      thumb: ImageDetail.fromJson(json['thumb'] as Map<String, dynamic>),
      pagesCount: (json['pagesCount'] as num?)?.toInt() ?? 0,
      epsCount: (json['epsCount'] as num?)?.toInt() ?? 0,
      finished: json['finished'] as bool,
      categories:
          (json['categories'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RecommendComicToJson(RecommendComic instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'thumb': instance.thumb,
      'pagesCount': instance.pagesCount,
      'epsCount': instance.epsCount,
      'finished': instance.finished,
      'categories': instance.categories,
      'likesCount': instance.likesCount,
    };

RecommendComics _$RecommendComicsFromJson(Map<String, dynamic> json) =>
    RecommendComics(
      comics:
          (json['comics'] as List<dynamic>)
              .map((e) => RecommendComic.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$RecommendComicsToJson(RecommendComics instance) =>
    <String, dynamic>{'comics': instance.comics};

ActionResponse _$ActionResponseFromJson(Map<String, dynamic> json) =>
    ActionResponse(action: json['action'] as String);

Map<String, dynamic> _$ActionResponseToJson(ActionResponse instance) =>
    <String, dynamic>{'action': instance.action};

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  uid: json['_id'] as String,
  content: json['content'] as String,
  user: Creator.fromJson(json['_user'] as Map<String, dynamic>),
  comic: json['_comic'] as String,
  totalComments: (json['totalComments'] as num?)?.toInt(),
  isTop: json['isTop'] as bool,
  hide: json['hide'] as bool,
  created_at: json['created_at'] as String,
  id: json['id'] as String,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  commentsCount: (json['commentsCount'] as num).toInt(),
  isLiked: json['isLiked'] as bool,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  '_id': instance.uid,
  'content': instance.content,
  '_user': instance.user,
  '_comic': instance.comic,
  'totalComments': instance.totalComments,
  'isTop': instance.isTop,
  'hide': instance.hide,
  'created_at': instance.created_at,
  'id': instance.id,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'isLiked': instance.isLiked,
};

Comments _$CommentsFromJson(Map<String, dynamic> json) => Comments(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: json['page'] as String,
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$CommentsToJson(Comments instance) => <String, dynamic>{
  'docs': instance.docs,
  'total': instance.total,
  'limit': instance.limit,
  'page': instance.page,
  'pages': instance.pages,
};

CommentsResponse _$CommentsResponseFromJson(Map<String, dynamic> json) =>
    CommentsResponse(
      comments: Comments.fromJson(json['comments'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CommentsResponseToJson(CommentsResponse instance) =>
    <String, dynamic>{'comments': instance.comments};

SubComment _$SubCommentFromJson(Map<String, dynamic> json) => SubComment(
  uid: json['_id'] as String,
  content: json['content'] as String,
  user: Creator.fromJson(json['_user'] as Map<String, dynamic>),
  created_at: json['created_at'] as String,
  hide: json['hide'] as bool,
  id: json['id'] as String,
  isLiked: json['isLiked'] as bool,
  isTop: json['isTop'] as bool,
  likesCount: (json['likesCount'] as num).toInt(),
  totalComments: (json['totalComments'] as num).toInt(),
  comic: json['_comic'] as String,
  parent: json['_parent'] as String,
);

Map<String, dynamic> _$SubCommentToJson(SubComment instance) =>
    <String, dynamic>{
      '_id': instance.uid,
      'content': instance.content,
      '_user': instance.user,
      'created_at': instance.created_at,
      'hide': instance.hide,
      'id': instance.id,
      'isLiked': instance.isLiked,
      'isTop': instance.isTop,
      'likesCount': instance.likesCount,
      'totalComments': instance.totalComments,
      '_comic': instance.comic,
      '_parent': instance.parent,
    };

SubComments _$SubCommentsFromJson(Map<String, dynamic> json) => SubComments(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => SubComment.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: json['page'] as String,
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$SubCommentsToJson(SubComments instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

SubCommentsResponse _$SubCommentsResponseFromJson(Map<String, dynamic> json) =>
    SubCommentsResponse(
      comments: SubComments.fromJson(json['comments'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubCommentsResponseToJson(
  SubCommentsResponse instance,
) => <String, dynamic>{'comments': instance.comments};

SearchComic _$SearchComicFromJson(Map<String, dynamic> json) => SearchComic(
  updated_at: json['updated_at'] as String,
  thumb: ImageDetail.fromJson(json['thumb'] as Map<String, dynamic>),
  author: json['author'] as String? ?? '??',
  description: json['description'] as String?,
  chineseTeam: json['chineseTeam'] as String?,
  created_at: json['created_at'] as String,
  finished: json['finished'] as bool,
  totalViews: (json['totalViews'] as num?)?.toInt(),
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
  totalLikes: (json['totalLikes'] as num?)?.toInt(),
  title: json['title'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  id: json['_id'] as String,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SearchComicToJson(SearchComic instance) =>
    <String, dynamic>{
      'updated_at': instance.updated_at,
      'thumb': instance.thumb,
      'author': instance.author,
      'description': instance.description,
      'chineseTeam': instance.chineseTeam,
      'created_at': instance.created_at,
      'finished': instance.finished,
      'totalViews': instance.totalViews,
      'categories': instance.categories,
      'totalLikes': instance.totalLikes,
      'title': instance.title,
      'tags': instance.tags,
      '_id': instance.id,
      'likesCount': instance.likesCount,
    };

SearchComics _$SearchComicsFromJson(Map<String, dynamic> json) => SearchComics(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => SearchComic.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$SearchComicsToJson(SearchComics instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    SearchResponse(
      comics: SearchComics.fromJson(json['comics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchResponseToJson(SearchResponse instance) =>
    <String, dynamic>{'comics': instance.comics};

ChapterImage _$ChapterImageFromJson(Map<String, dynamic> json) => ChapterImage(
  uid: json['_id'] as String,
  id: json['id'] as String?,
  media: ImageDetail.fromJson(json['media'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChapterImageToJson(ChapterImage instance) =>
    <String, dynamic>{
      '_id': instance.uid,
      'id': instance.id,
      'media': instance.media,
    };

ChaptersImages _$ChaptersImagesFromJson(Map<String, dynamic> json) =>
    ChaptersImages(
      docs:
          (json['docs'] as List<dynamic>)
              .map((e) => ChapterImage.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$ChaptersImagesToJson(ChaptersImages instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

ChapterEpisode _$ChapterEpisodeFromJson(Map<String, dynamic> json) =>
    ChapterEpisode(id: json['_id'] as String, title: json['title'] as String);

Map<String, dynamic> _$ChapterEpisodeToJson(ChapterEpisode instance) =>
    <String, dynamic>{'_id': instance.id, 'title': instance.title};

FetchChapterImagesResponse _$FetchChapterImagesResponseFromJson(
  Map<String, dynamic> json,
) => FetchChapterImagesResponse(
  pages: ChaptersImages.fromJson(json['pages'] as Map<String, dynamic>),
  ep: ChapterEpisode.fromJson(json['ep'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FetchChapterImagesResponseToJson(
  FetchChapterImagesResponse instance,
) => <String, dynamic>{'pages': instance.pages, 'ep': instance.ep};

HistoryDoc _$HistoryDocFromJson(Map<String, dynamic> json) => HistoryDoc(
  id: json['id'] as String?,
  title: json['title'] as String,
  author: json['author'] as String? ?? '',
  totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
  totalLikes: (json['totalLikes'] as num?)?.toInt(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  epsCount: (json['epsCount'] as num).toInt(),
  finished: json['finished'] as bool,
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
  thumb: ImageDetail.fromJson(json['thumb'] as Map<String, dynamic>),
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  uid: json['_id'] as String,
  updatedAt: json['updatedAt'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$HistoryDocToJson(HistoryDoc instance) =>
    <String, dynamic>{
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
      'updatedAt': instance.updatedAt,
      'createdAt': instance.createdAt,
    };
