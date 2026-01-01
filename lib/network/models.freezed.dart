// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Comics {

 List<Doc> get docs; int get limit; int get page; int get pages; int get total;
/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicsCopyWith<Comics> get copyWith => _$ComicsCopyWithImpl<Comics>(this as Comics, _$identity);

  /// Serializes this Comics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comics&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),limit,page,pages,total);

@override
String toString() {
  return 'Comics(docs: $docs, limit: $limit, page: $page, pages: $pages, total: $total)';
}


}

/// @nodoc
abstract mixin class $ComicsCopyWith<$Res>  {
  factory $ComicsCopyWith(Comics value, $Res Function(Comics) _then) = _$ComicsCopyWithImpl;
@useResult
$Res call({
 List<Doc> docs, int limit, int page, int pages, int total
});




}
/// @nodoc
class _$ComicsCopyWithImpl<$Res>
    implements $ComicsCopyWith<$Res> {
  _$ComicsCopyWithImpl(this._self, this._then);

  final Comics _self;
  final $Res Function(Comics) _then;

/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? limit = null,Object? page = null,Object? pages = null,Object? total = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Comics].
extension ComicsPatterns on Comics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comics value)  $default,){
final _that = this;
switch (_that) {
case _Comics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comics value)?  $default,){
final _that = this;
switch (_that) {
case _Comics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Doc> docs,  int limit,  int page,  int pages,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comics() when $default != null:
return $default(_that.docs,_that.limit,_that.page,_that.pages,_that.total);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Doc> docs,  int limit,  int page,  int pages,  int total)  $default,) {final _that = this;
switch (_that) {
case _Comics():
return $default(_that.docs,_that.limit,_that.page,_that.pages,_that.total);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Doc> docs,  int limit,  int page,  int pages,  int total)?  $default,) {final _that = this;
switch (_that) {
case _Comics() when $default != null:
return $default(_that.docs,_that.limit,_that.page,_that.pages,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comics implements Comics {
  const _Comics({required final  List<Doc> docs, required this.limit, required this.page, required this.pages, required this.total}): _docs = docs;
  factory _Comics.fromJson(Map<String, dynamic> json) => _$ComicsFromJson(json);

 final  List<Doc> _docs;
@override List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override final  int limit;
@override final  int page;
@override final  int pages;
@override final  int total;

/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicsCopyWith<_Comics> get copyWith => __$ComicsCopyWithImpl<_Comics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comics&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),limit,page,pages,total);

@override
String toString() {
  return 'Comics(docs: $docs, limit: $limit, page: $page, pages: $pages, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ComicsCopyWith<$Res> implements $ComicsCopyWith<$Res> {
  factory _$ComicsCopyWith(_Comics value, $Res Function(_Comics) _then) = __$ComicsCopyWithImpl;
@override @useResult
$Res call({
 List<Doc> docs, int limit, int page, int pages, int total
});




}
/// @nodoc
class __$ComicsCopyWithImpl<$Res>
    implements _$ComicsCopyWith<$Res> {
  __$ComicsCopyWithImpl(this._self, this._then);

  final _Comics _self;
  final $Res Function(_Comics) _then;

/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? limit = null,Object? page = null,Object? pages = null,Object? total = null,}) {
  return _then(_Comics(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ComicsResponse {

 Comics get comics;
/// Create a copy of ComicsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicsResponseCopyWith<ComicsResponse> get copyWith => _$ComicsResponseCopyWithImpl<ComicsResponse>(this as ComicsResponse, _$identity);

  /// Serializes this ComicsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicsResponse&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'ComicsResponse(comics: $comics)';
}


}

/// @nodoc
abstract mixin class $ComicsResponseCopyWith<$Res>  {
  factory $ComicsResponseCopyWith(ComicsResponse value, $Res Function(ComicsResponse) _then) = _$ComicsResponseCopyWithImpl;
@useResult
$Res call({
 Comics comics
});


$ComicsCopyWith<$Res> get comics;

}
/// @nodoc
class _$ComicsResponseCopyWithImpl<$Res>
    implements $ComicsResponseCopyWith<$Res> {
  _$ComicsResponseCopyWithImpl(this._self, this._then);

  final ComicsResponse _self;
  final $Res Function(ComicsResponse) _then;

/// Create a copy of ComicsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comics = null,}) {
  return _then(_self.copyWith(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Comics,
  ));
}
/// Create a copy of ComicsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicsCopyWith<$Res> get comics {
  
  return $ComicsCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicsResponse].
extension ComicsResponsePatterns on ComicsResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicsResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicsResponse value)  $default,){
final _that = this;
switch (_that) {
case _ComicsResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ComicsResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Comics comics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicsResponse() when $default != null:
return $default(_that.comics);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Comics comics)  $default,) {final _that = this;
switch (_that) {
case _ComicsResponse():
return $default(_that.comics);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Comics comics)?  $default,) {final _that = this;
switch (_that) {
case _ComicsResponse() when $default != null:
return $default(_that.comics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicsResponse implements ComicsResponse {
  const _ComicsResponse({required this.comics});
  factory _ComicsResponse.fromJson(Map<String, dynamic> json) => _$ComicsResponseFromJson(json);

@override final  Comics comics;

/// Create a copy of ComicsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicsResponseCopyWith<_ComicsResponse> get copyWith => __$ComicsResponseCopyWithImpl<_ComicsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicsResponse&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'ComicsResponse(comics: $comics)';
}


}

/// @nodoc
abstract mixin class _$ComicsResponseCopyWith<$Res> implements $ComicsResponseCopyWith<$Res> {
  factory _$ComicsResponseCopyWith(_ComicsResponse value, $Res Function(_ComicsResponse) _then) = __$ComicsResponseCopyWithImpl;
@override @useResult
$Res call({
 Comics comics
});


@override $ComicsCopyWith<$Res> get comics;

}
/// @nodoc
class __$ComicsResponseCopyWithImpl<$Res>
    implements _$ComicsResponseCopyWith<$Res> {
  __$ComicsResponseCopyWithImpl(this._self, this._then);

  final _ComicsResponse _self;
  final $Res Function(_ComicsResponse) _then;

/// Create a copy of ComicsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comics = null,}) {
  return _then(_ComicsResponse(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Comics,
  ));
}

/// Create a copy of ComicsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicsCopyWith<$Res> get comics {
  
  return $ComicsCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}


/// @nodoc
mixin _$Comments {

 List<Comment> get docs; int get total; int get limit;@JsonKey(fromJson: pageFormat) int get page; int get pages;
/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsCopyWith<Comments> get copyWith => _$CommentsCopyWithImpl<Comments>(this as Comments, _$identity);

  /// Serializes this Comments to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comments&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $CommentsCopyWith<$Res>  {
  factory $CommentsCopyWith(Comments value, $Res Function(Comments) _then) = _$CommentsCopyWithImpl;
@useResult
$Res call({
 List<Comment> docs, int total, int limit,@JsonKey(fromJson: pageFormat) int page, int pages
});




}
/// @nodoc
class _$CommentsCopyWithImpl<$Res>
    implements $CommentsCopyWith<$Res> {
  _$CommentsCopyWithImpl(this._self, this._then);

  final Comments _self;
  final $Res Function(Comments) _then;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Comment>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Comments].
extension CommentsPatterns on Comments {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comments() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comments value)  $default,){
final _that = this;
switch (_that) {
case _Comments():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comments value)?  $default,){
final _that = this;
switch (_that) {
case _Comments() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Comment> docs,  int total,  int limit, @JsonKey(fromJson: pageFormat)  int page,  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comments() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Comment> docs,  int total,  int limit, @JsonKey(fromJson: pageFormat)  int page,  int pages)  $default,) {final _that = this;
switch (_that) {
case _Comments():
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Comment> docs,  int total,  int limit, @JsonKey(fromJson: pageFormat)  int page,  int pages)?  $default,) {final _that = this;
switch (_that) {
case _Comments() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comments implements Comments {
  const _Comments({required final  List<Comment> docs, required this.total, this.limit = 20, @JsonKey(fromJson: pageFormat) required this.page, required this.pages}): _docs = docs;
  factory _Comments.fromJson(Map<String, dynamic> json) => _$CommentsFromJson(json);

 final  List<Comment> _docs;
@override List<Comment> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override final  int total;
@override@JsonKey() final  int limit;
@override@JsonKey(fromJson: pageFormat) final  int page;
@override final  int pages;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsCopyWith<_Comments> get copyWith => __$CommentsCopyWithImpl<_Comments>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comments&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$CommentsCopyWith<$Res> implements $CommentsCopyWith<$Res> {
  factory _$CommentsCopyWith(_Comments value, $Res Function(_Comments) _then) = __$CommentsCopyWithImpl;
@override @useResult
$Res call({
 List<Comment> docs, int total, int limit,@JsonKey(fromJson: pageFormat) int page, int pages
});




}
/// @nodoc
class __$CommentsCopyWithImpl<$Res>
    implements _$CommentsCopyWith<$Res> {
  __$CommentsCopyWithImpl(this._self, this._then);

  final _Comments _self;
  final $Res Function(_Comments) _then;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_Comments(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Comment>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CommentsResponse {

 Comments get comments;
/// Create a copy of CommentsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsResponseCopyWith<CommentsResponse> get copyWith => _$CommentsResponseCopyWithImpl<CommentsResponse>(this as CommentsResponse, _$identity);

  /// Serializes this CommentsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsResponse&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'CommentsResponse(comments: $comments)';
}


}

/// @nodoc
abstract mixin class $CommentsResponseCopyWith<$Res>  {
  factory $CommentsResponseCopyWith(CommentsResponse value, $Res Function(CommentsResponse) _then) = _$CommentsResponseCopyWithImpl;
@useResult
$Res call({
 Comments comments
});


$CommentsCopyWith<$Res> get comments;

}
/// @nodoc
class _$CommentsResponseCopyWithImpl<$Res>
    implements $CommentsResponseCopyWith<$Res> {
  _$CommentsResponseCopyWithImpl(this._self, this._then);

  final CommentsResponse _self;
  final $Res Function(CommentsResponse) _then;

/// Create a copy of CommentsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comments = null,}) {
  return _then(_self.copyWith(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as Comments,
  ));
}
/// Create a copy of CommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentsCopyWith<$Res> get comments {
  
  return $CommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommentsResponse].
extension CommentsResponsePatterns on CommentsResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentsResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentsResponse value)  $default,){
final _that = this;
switch (_that) {
case _CommentsResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CommentsResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Comments comments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentsResponse() when $default != null:
return $default(_that.comments);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Comments comments)  $default,) {final _that = this;
switch (_that) {
case _CommentsResponse():
return $default(_that.comments);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Comments comments)?  $default,) {final _that = this;
switch (_that) {
case _CommentsResponse() when $default != null:
return $default(_that.comments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentsResponse implements CommentsResponse {
  const _CommentsResponse({required this.comments});
  factory _CommentsResponse.fromJson(Map<String, dynamic> json) => _$CommentsResponseFromJson(json);

@override final  Comments comments;

/// Create a copy of CommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsResponseCopyWith<_CommentsResponse> get copyWith => __$CommentsResponseCopyWithImpl<_CommentsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsResponse&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'CommentsResponse(comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$CommentsResponseCopyWith<$Res> implements $CommentsResponseCopyWith<$Res> {
  factory _$CommentsResponseCopyWith(_CommentsResponse value, $Res Function(_CommentsResponse) _then) = __$CommentsResponseCopyWithImpl;
@override @useResult
$Res call({
 Comments comments
});


@override $CommentsCopyWith<$Res> get comments;

}
/// @nodoc
class __$CommentsResponseCopyWithImpl<$Res>
    implements _$CommentsResponseCopyWith<$Res> {
  __$CommentsResponseCopyWithImpl(this._self, this._then);

  final _CommentsResponse _self;
  final $Res Function(_CommentsResponse) _then;

/// Create a copy of CommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comments = null,}) {
  return _then(_CommentsResponse(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as Comments,
  ));
}

/// Create a copy of CommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentsCopyWith<$Res> get comments {
  
  return $CommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// @nodoc
mixin _$SubComments {

 List<SubComment> get docs; int get total; int get limit; String get page; int get pages;
/// Create a copy of SubComments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubCommentsCopyWith<SubComments> get copyWith => _$SubCommentsCopyWithImpl<SubComments>(this as SubComments, _$identity);

  /// Serializes this SubComments to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubComments&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'SubComments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $SubCommentsCopyWith<$Res>  {
  factory $SubCommentsCopyWith(SubComments value, $Res Function(SubComments) _then) = _$SubCommentsCopyWithImpl;
@useResult
$Res call({
 List<SubComment> docs, int total, int limit, String page, int pages
});




}
/// @nodoc
class _$SubCommentsCopyWithImpl<$Res>
    implements $SubCommentsCopyWith<$Res> {
  _$SubCommentsCopyWithImpl(this._self, this._then);

  final SubComments _self;
  final $Res Function(SubComments) _then;

/// Create a copy of SubComments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<SubComment>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SubComments].
extension SubCommentsPatterns on SubComments {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubComments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubComments() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubComments value)  $default,){
final _that = this;
switch (_that) {
case _SubComments():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubComments value)?  $default,){
final _that = this;
switch (_that) {
case _SubComments() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubComment> docs,  int total,  int limit,  String page,  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubComments() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubComment> docs,  int total,  int limit,  String page,  int pages)  $default,) {final _that = this;
switch (_that) {
case _SubComments():
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubComment> docs,  int total,  int limit,  String page,  int pages)?  $default,) {final _that = this;
switch (_that) {
case _SubComments() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubComments implements SubComments {
  const _SubComments({required final  List<SubComment> docs, required this.total, required this.limit, required this.page, required this.pages}): _docs = docs;
  factory _SubComments.fromJson(Map<String, dynamic> json) => _$SubCommentsFromJson(json);

 final  List<SubComment> _docs;
@override List<SubComment> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override final  int total;
@override final  int limit;
@override final  String page;
@override final  int pages;

/// Create a copy of SubComments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubCommentsCopyWith<_SubComments> get copyWith => __$SubCommentsCopyWithImpl<_SubComments>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubCommentsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubComments&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'SubComments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$SubCommentsCopyWith<$Res> implements $SubCommentsCopyWith<$Res> {
  factory _$SubCommentsCopyWith(_SubComments value, $Res Function(_SubComments) _then) = __$SubCommentsCopyWithImpl;
@override @useResult
$Res call({
 List<SubComment> docs, int total, int limit, String page, int pages
});




}
/// @nodoc
class __$SubCommentsCopyWithImpl<$Res>
    implements _$SubCommentsCopyWith<$Res> {
  __$SubCommentsCopyWithImpl(this._self, this._then);

  final _SubComments _self;
  final $Res Function(_SubComments) _then;

/// Create a copy of SubComments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_SubComments(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<SubComment>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SubCommentsResponse {

 SubComments get comments;
/// Create a copy of SubCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubCommentsResponseCopyWith<SubCommentsResponse> get copyWith => _$SubCommentsResponseCopyWithImpl<SubCommentsResponse>(this as SubCommentsResponse, _$identity);

  /// Serializes this SubCommentsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubCommentsResponse&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'SubCommentsResponse(comments: $comments)';
}


}

/// @nodoc
abstract mixin class $SubCommentsResponseCopyWith<$Res>  {
  factory $SubCommentsResponseCopyWith(SubCommentsResponse value, $Res Function(SubCommentsResponse) _then) = _$SubCommentsResponseCopyWithImpl;
@useResult
$Res call({
 SubComments comments
});


$SubCommentsCopyWith<$Res> get comments;

}
/// @nodoc
class _$SubCommentsResponseCopyWithImpl<$Res>
    implements $SubCommentsResponseCopyWith<$Res> {
  _$SubCommentsResponseCopyWithImpl(this._self, this._then);

  final SubCommentsResponse _self;
  final $Res Function(SubCommentsResponse) _then;

/// Create a copy of SubCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comments = null,}) {
  return _then(_self.copyWith(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as SubComments,
  ));
}
/// Create a copy of SubCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubCommentsCopyWith<$Res> get comments {
  
  return $SubCommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubCommentsResponse].
extension SubCommentsResponsePatterns on SubCommentsResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubCommentsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubCommentsResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubCommentsResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubCommentsResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubCommentsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubCommentsResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubComments comments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubCommentsResponse() when $default != null:
return $default(_that.comments);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubComments comments)  $default,) {final _that = this;
switch (_that) {
case _SubCommentsResponse():
return $default(_that.comments);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubComments comments)?  $default,) {final _that = this;
switch (_that) {
case _SubCommentsResponse() when $default != null:
return $default(_that.comments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubCommentsResponse implements SubCommentsResponse {
  const _SubCommentsResponse({required this.comments});
  factory _SubCommentsResponse.fromJson(Map<String, dynamic> json) => _$SubCommentsResponseFromJson(json);

@override final  SubComments comments;

/// Create a copy of SubCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubCommentsResponseCopyWith<_SubCommentsResponse> get copyWith => __$SubCommentsResponseCopyWithImpl<_SubCommentsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubCommentsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubCommentsResponse&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'SubCommentsResponse(comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$SubCommentsResponseCopyWith<$Res> implements $SubCommentsResponseCopyWith<$Res> {
  factory _$SubCommentsResponseCopyWith(_SubCommentsResponse value, $Res Function(_SubCommentsResponse) _then) = __$SubCommentsResponseCopyWithImpl;
@override @useResult
$Res call({
 SubComments comments
});


@override $SubCommentsCopyWith<$Res> get comments;

}
/// @nodoc
class __$SubCommentsResponseCopyWithImpl<$Res>
    implements _$SubCommentsResponseCopyWith<$Res> {
  __$SubCommentsResponseCopyWithImpl(this._self, this._then);

  final _SubCommentsResponse _self;
  final $Res Function(_SubCommentsResponse) _then;

/// Create a copy of SubCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comments = null,}) {
  return _then(_SubCommentsResponse(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as SubComments,
  ));
}

/// Create a copy of SubCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubCommentsCopyWith<$Res> get comments {
  
  return $SubCommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// @nodoc
mixin _$SearchComics {

 List<SearchComic> get docs; int get total; int get limit; int get page; int get pages;
/// Create a copy of SearchComics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchComicsCopyWith<SearchComics> get copyWith => _$SearchComicsCopyWithImpl<SearchComics>(this as SearchComics, _$identity);

  /// Serializes this SearchComics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchComics&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'SearchComics(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $SearchComicsCopyWith<$Res>  {
  factory $SearchComicsCopyWith(SearchComics value, $Res Function(SearchComics) _then) = _$SearchComicsCopyWithImpl;
@useResult
$Res call({
 List<SearchComic> docs, int total, int limit, int page, int pages
});




}
/// @nodoc
class _$SearchComicsCopyWithImpl<$Res>
    implements $SearchComicsCopyWith<$Res> {
  _$SearchComicsCopyWithImpl(this._self, this._then);

  final SearchComics _self;
  final $Res Function(SearchComics) _then;

/// Create a copy of SearchComics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<SearchComic>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchComics].
extension SearchComicsPatterns on SearchComics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchComics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchComics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchComics value)  $default,){
final _that = this;
switch (_that) {
case _SearchComics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchComics value)?  $default,){
final _that = this;
switch (_that) {
case _SearchComics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchComic> docs,  int total,  int limit,  int page,  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchComics() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchComic> docs,  int total,  int limit,  int page,  int pages)  $default,) {final _that = this;
switch (_that) {
case _SearchComics():
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchComic> docs,  int total,  int limit,  int page,  int pages)?  $default,) {final _that = this;
switch (_that) {
case _SearchComics() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchComics implements SearchComics {
  const _SearchComics({required final  List<SearchComic> docs, required this.total, required this.limit, required this.page, required this.pages}): _docs = docs;
  factory _SearchComics.fromJson(Map<String, dynamic> json) => _$SearchComicsFromJson(json);

 final  List<SearchComic> _docs;
@override List<SearchComic> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override final  int total;
@override final  int limit;
@override final  int page;
@override final  int pages;

/// Create a copy of SearchComics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchComicsCopyWith<_SearchComics> get copyWith => __$SearchComicsCopyWithImpl<_SearchComics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchComicsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchComics&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'SearchComics(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$SearchComicsCopyWith<$Res> implements $SearchComicsCopyWith<$Res> {
  factory _$SearchComicsCopyWith(_SearchComics value, $Res Function(_SearchComics) _then) = __$SearchComicsCopyWithImpl;
@override @useResult
$Res call({
 List<SearchComic> docs, int total, int limit, int page, int pages
});




}
/// @nodoc
class __$SearchComicsCopyWithImpl<$Res>
    implements _$SearchComicsCopyWith<$Res> {
  __$SearchComicsCopyWithImpl(this._self, this._then);

  final _SearchComics _self;
  final $Res Function(_SearchComics) _then;

/// Create a copy of SearchComics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_SearchComics(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<SearchComic>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SearchResponse {

 SearchComics get comics;
/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResponseCopyWith<SearchResponse> get copyWith => _$SearchResponseCopyWithImpl<SearchResponse>(this as SearchResponse, _$identity);

  /// Serializes this SearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResponse&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'SearchResponse(comics: $comics)';
}


}

/// @nodoc
abstract mixin class $SearchResponseCopyWith<$Res>  {
  factory $SearchResponseCopyWith(SearchResponse value, $Res Function(SearchResponse) _then) = _$SearchResponseCopyWithImpl;
@useResult
$Res call({
 SearchComics comics
});


$SearchComicsCopyWith<$Res> get comics;

}
/// @nodoc
class _$SearchResponseCopyWithImpl<$Res>
    implements $SearchResponseCopyWith<$Res> {
  _$SearchResponseCopyWithImpl(this._self, this._then);

  final SearchResponse _self;
  final $Res Function(SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comics = null,}) {
  return _then(_self.copyWith(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as SearchComics,
  ));
}
/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchComicsCopyWith<$Res> get comics {
  
  return $SearchComicsCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResponse].
extension SearchResponsePatterns on SearchResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _SearchResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchComics comics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that.comics);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchComics comics)  $default,) {final _that = this;
switch (_that) {
case _SearchResponse():
return $default(_that.comics);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchComics comics)?  $default,) {final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that.comics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResponse implements SearchResponse {
  const _SearchResponse({required this.comics});
  factory _SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);

@override final  SearchComics comics;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResponseCopyWith<_SearchResponse> get copyWith => __$SearchResponseCopyWithImpl<_SearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResponse&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'SearchResponse(comics: $comics)';
}


}

/// @nodoc
abstract mixin class _$SearchResponseCopyWith<$Res> implements $SearchResponseCopyWith<$Res> {
  factory _$SearchResponseCopyWith(_SearchResponse value, $Res Function(_SearchResponse) _then) = __$SearchResponseCopyWithImpl;
@override @useResult
$Res call({
 SearchComics comics
});


@override $SearchComicsCopyWith<$Res> get comics;

}
/// @nodoc
class __$SearchResponseCopyWithImpl<$Res>
    implements _$SearchResponseCopyWith<$Res> {
  __$SearchResponseCopyWithImpl(this._self, this._then);

  final _SearchResponse _self;
  final $Res Function(_SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comics = null,}) {
  return _then(_SearchResponse(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as SearchComics,
  ));
}

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchComicsCopyWith<$Res> get comics {
  
  return $SearchComicsCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}


/// @nodoc
mixin _$PersonalComments {

 List<PersonalComment> get docs; int get pages; int get total; int get limit; String get page;
/// Create a copy of PersonalComments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalCommentsCopyWith<PersonalComments> get copyWith => _$PersonalCommentsCopyWithImpl<PersonalComments>(this as PersonalComments, _$identity);

  /// Serializes this PersonalComments to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalComments&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),pages,total,limit,page);

@override
String toString() {
  return 'PersonalComments(docs: $docs, pages: $pages, total: $total, limit: $limit, page: $page)';
}


}

/// @nodoc
abstract mixin class $PersonalCommentsCopyWith<$Res>  {
  factory $PersonalCommentsCopyWith(PersonalComments value, $Res Function(PersonalComments) _then) = _$PersonalCommentsCopyWithImpl;
@useResult
$Res call({
 List<PersonalComment> docs, int pages, int total, int limit, String page
});




}
/// @nodoc
class _$PersonalCommentsCopyWithImpl<$Res>
    implements $PersonalCommentsCopyWith<$Res> {
  _$PersonalCommentsCopyWithImpl(this._self, this._then);

  final PersonalComments _self;
  final $Res Function(PersonalComments) _then;

/// Create a copy of PersonalComments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? pages = null,Object? total = null,Object? limit = null,Object? page = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<PersonalComment>,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalComments].
extension PersonalCommentsPatterns on PersonalComments {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalComments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalComments() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalComments value)  $default,){
final _that = this;
switch (_that) {
case _PersonalComments():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalComments value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalComments() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PersonalComment> docs,  int pages,  int total,  int limit,  String page)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalComments() when $default != null:
return $default(_that.docs,_that.pages,_that.total,_that.limit,_that.page);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PersonalComment> docs,  int pages,  int total,  int limit,  String page)  $default,) {final _that = this;
switch (_that) {
case _PersonalComments():
return $default(_that.docs,_that.pages,_that.total,_that.limit,_that.page);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PersonalComment> docs,  int pages,  int total,  int limit,  String page)?  $default,) {final _that = this;
switch (_that) {
case _PersonalComments() when $default != null:
return $default(_that.docs,_that.pages,_that.total,_that.limit,_that.page);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalComments implements PersonalComments {
  const _PersonalComments({required final  List<PersonalComment> docs, required this.pages, required this.total, required this.limit, required this.page}): _docs = docs;
  factory _PersonalComments.fromJson(Map<String, dynamic> json) => _$PersonalCommentsFromJson(json);

 final  List<PersonalComment> _docs;
@override List<PersonalComment> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override final  int pages;
@override final  int total;
@override final  int limit;
@override final  String page;

/// Create a copy of PersonalComments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalCommentsCopyWith<_PersonalComments> get copyWith => __$PersonalCommentsCopyWithImpl<_PersonalComments>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalCommentsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalComments&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),pages,total,limit,page);

@override
String toString() {
  return 'PersonalComments(docs: $docs, pages: $pages, total: $total, limit: $limit, page: $page)';
}


}

/// @nodoc
abstract mixin class _$PersonalCommentsCopyWith<$Res> implements $PersonalCommentsCopyWith<$Res> {
  factory _$PersonalCommentsCopyWith(_PersonalComments value, $Res Function(_PersonalComments) _then) = __$PersonalCommentsCopyWithImpl;
@override @useResult
$Res call({
 List<PersonalComment> docs, int pages, int total, int limit, String page
});




}
/// @nodoc
class __$PersonalCommentsCopyWithImpl<$Res>
    implements _$PersonalCommentsCopyWith<$Res> {
  __$PersonalCommentsCopyWithImpl(this._self, this._then);

  final _PersonalComments _self;
  final $Res Function(_PersonalComments) _then;

/// Create a copy of PersonalComments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? pages = null,Object? total = null,Object? limit = null,Object? page = null,}) {
  return _then(_PersonalComments(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<PersonalComment>,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PersonalCommentsResponse {

 PersonalComments get comments;
/// Create a copy of PersonalCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalCommentsResponseCopyWith<PersonalCommentsResponse> get copyWith => _$PersonalCommentsResponseCopyWithImpl<PersonalCommentsResponse>(this as PersonalCommentsResponse, _$identity);

  /// Serializes this PersonalCommentsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalCommentsResponse&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'PersonalCommentsResponse(comments: $comments)';
}


}

/// @nodoc
abstract mixin class $PersonalCommentsResponseCopyWith<$Res>  {
  factory $PersonalCommentsResponseCopyWith(PersonalCommentsResponse value, $Res Function(PersonalCommentsResponse) _then) = _$PersonalCommentsResponseCopyWithImpl;
@useResult
$Res call({
 PersonalComments comments
});


$PersonalCommentsCopyWith<$Res> get comments;

}
/// @nodoc
class _$PersonalCommentsResponseCopyWithImpl<$Res>
    implements $PersonalCommentsResponseCopyWith<$Res> {
  _$PersonalCommentsResponseCopyWithImpl(this._self, this._then);

  final PersonalCommentsResponse _self;
  final $Res Function(PersonalCommentsResponse) _then;

/// Create a copy of PersonalCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comments = null,}) {
  return _then(_self.copyWith(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as PersonalComments,
  ));
}
/// Create a copy of PersonalCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonalCommentsCopyWith<$Res> get comments {
  
  return $PersonalCommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// Adds pattern-matching-related methods to [PersonalCommentsResponse].
extension PersonalCommentsResponsePatterns on PersonalCommentsResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalCommentsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalCommentsResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalCommentsResponse value)  $default,){
final _that = this;
switch (_that) {
case _PersonalCommentsResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalCommentsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalCommentsResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PersonalComments comments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalCommentsResponse() when $default != null:
return $default(_that.comments);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PersonalComments comments)  $default,) {final _that = this;
switch (_that) {
case _PersonalCommentsResponse():
return $default(_that.comments);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PersonalComments comments)?  $default,) {final _that = this;
switch (_that) {
case _PersonalCommentsResponse() when $default != null:
return $default(_that.comments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalCommentsResponse implements PersonalCommentsResponse {
  const _PersonalCommentsResponse({required this.comments});
  factory _PersonalCommentsResponse.fromJson(Map<String, dynamic> json) => _$PersonalCommentsResponseFromJson(json);

@override final  PersonalComments comments;

/// Create a copy of PersonalCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalCommentsResponseCopyWith<_PersonalCommentsResponse> get copyWith => __$PersonalCommentsResponseCopyWithImpl<_PersonalCommentsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalCommentsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalCommentsResponse&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'PersonalCommentsResponse(comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$PersonalCommentsResponseCopyWith<$Res> implements $PersonalCommentsResponseCopyWith<$Res> {
  factory _$PersonalCommentsResponseCopyWith(_PersonalCommentsResponse value, $Res Function(_PersonalCommentsResponse) _then) = __$PersonalCommentsResponseCopyWithImpl;
@override @useResult
$Res call({
 PersonalComments comments
});


@override $PersonalCommentsCopyWith<$Res> get comments;

}
/// @nodoc
class __$PersonalCommentsResponseCopyWithImpl<$Res>
    implements _$PersonalCommentsResponseCopyWith<$Res> {
  __$PersonalCommentsResponseCopyWithImpl(this._self, this._then);

  final _PersonalCommentsResponse _self;
  final $Res Function(_PersonalCommentsResponse) _then;

/// Create a copy of PersonalCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comments = null,}) {
  return _then(_PersonalCommentsResponse(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as PersonalComments,
  ));
}

/// Create a copy of PersonalCommentsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonalCommentsCopyWith<$Res> get comments {
  
  return $PersonalCommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// @nodoc
mixin _$NotificationsResponse {

 NotificationsData get notifications;
/// Create a copy of NotificationsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationsResponseCopyWith<NotificationsResponse> get copyWith => _$NotificationsResponseCopyWithImpl<NotificationsResponse>(this as NotificationsResponse, _$identity);

  /// Serializes this NotificationsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationsResponse&&(identical(other.notifications, notifications) || other.notifications == notifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notifications);

@override
String toString() {
  return 'NotificationsResponse(notifications: $notifications)';
}


}

/// @nodoc
abstract mixin class $NotificationsResponseCopyWith<$Res>  {
  factory $NotificationsResponseCopyWith(NotificationsResponse value, $Res Function(NotificationsResponse) _then) = _$NotificationsResponseCopyWithImpl;
@useResult
$Res call({
 NotificationsData notifications
});


$NotificationsDataCopyWith<$Res> get notifications;

}
/// @nodoc
class _$NotificationsResponseCopyWithImpl<$Res>
    implements $NotificationsResponseCopyWith<$Res> {
  _$NotificationsResponseCopyWithImpl(this._self, this._then);

  final NotificationsResponse _self;
  final $Res Function(NotificationsResponse) _then;

/// Create a copy of NotificationsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notifications = null,}) {
  return _then(_self.copyWith(
notifications: null == notifications ? _self.notifications : notifications // ignore: cast_nullable_to_non_nullable
as NotificationsData,
  ));
}
/// Create a copy of NotificationsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationsDataCopyWith<$Res> get notifications {
  
  return $NotificationsDataCopyWith<$Res>(_self.notifications, (value) {
    return _then(_self.copyWith(notifications: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationsResponse].
extension NotificationsResponsePatterns on NotificationsResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationsResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationsResponse value)  $default,){
final _that = this;
switch (_that) {
case _NotificationsResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationsResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NotificationsData notifications)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationsResponse() when $default != null:
return $default(_that.notifications);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NotificationsData notifications)  $default,) {final _that = this;
switch (_that) {
case _NotificationsResponse():
return $default(_that.notifications);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NotificationsData notifications)?  $default,) {final _that = this;
switch (_that) {
case _NotificationsResponse() when $default != null:
return $default(_that.notifications);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationsResponse implements NotificationsResponse {
  const _NotificationsResponse({required this.notifications});
  factory _NotificationsResponse.fromJson(Map<String, dynamic> json) => _$NotificationsResponseFromJson(json);

@override final  NotificationsData notifications;

/// Create a copy of NotificationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationsResponseCopyWith<_NotificationsResponse> get copyWith => __$NotificationsResponseCopyWithImpl<_NotificationsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationsResponse&&(identical(other.notifications, notifications) || other.notifications == notifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notifications);

@override
String toString() {
  return 'NotificationsResponse(notifications: $notifications)';
}


}

/// @nodoc
abstract mixin class _$NotificationsResponseCopyWith<$Res> implements $NotificationsResponseCopyWith<$Res> {
  factory _$NotificationsResponseCopyWith(_NotificationsResponse value, $Res Function(_NotificationsResponse) _then) = __$NotificationsResponseCopyWithImpl;
@override @useResult
$Res call({
 NotificationsData notifications
});


@override $NotificationsDataCopyWith<$Res> get notifications;

}
/// @nodoc
class __$NotificationsResponseCopyWithImpl<$Res>
    implements _$NotificationsResponseCopyWith<$Res> {
  __$NotificationsResponseCopyWithImpl(this._self, this._then);

  final _NotificationsResponse _self;
  final $Res Function(_NotificationsResponse) _then;

/// Create a copy of NotificationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notifications = null,}) {
  return _then(_NotificationsResponse(
notifications: null == notifications ? _self.notifications : notifications // ignore: cast_nullable_to_non_nullable
as NotificationsData,
  ));
}

/// Create a copy of NotificationsResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationsDataCopyWith<$Res> get notifications {
  
  return $NotificationsDataCopyWith<$Res>(_self.notifications, (value) {
    return _then(_self.copyWith(notifications: value));
  });
}
}


/// @nodoc
mixin _$NotificationsData {

 List<NotificationDoc> get docs; int get limit; int get page; int get pages; int get total;
/// Create a copy of NotificationsData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationsDataCopyWith<NotificationsData> get copyWith => _$NotificationsDataCopyWithImpl<NotificationsData>(this as NotificationsData, _$identity);

  /// Serializes this NotificationsData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationsData&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),limit,page,pages,total);

@override
String toString() {
  return 'NotificationsData(docs: $docs, limit: $limit, page: $page, pages: $pages, total: $total)';
}


}

/// @nodoc
abstract mixin class $NotificationsDataCopyWith<$Res>  {
  factory $NotificationsDataCopyWith(NotificationsData value, $Res Function(NotificationsData) _then) = _$NotificationsDataCopyWithImpl;
@useResult
$Res call({
 List<NotificationDoc> docs, int limit, int page, int pages, int total
});




}
/// @nodoc
class _$NotificationsDataCopyWithImpl<$Res>
    implements $NotificationsDataCopyWith<$Res> {
  _$NotificationsDataCopyWithImpl(this._self, this._then);

  final NotificationsData _self;
  final $Res Function(NotificationsData) _then;

/// Create a copy of NotificationsData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? limit = null,Object? page = null,Object? pages = null,Object? total = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<NotificationDoc>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationsData].
extension NotificationsDataPatterns on NotificationsData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationsData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationsData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationsData value)  $default,){
final _that = this;
switch (_that) {
case _NotificationsData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationsData value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationsData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationDoc> docs,  int limit,  int page,  int pages,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationsData() when $default != null:
return $default(_that.docs,_that.limit,_that.page,_that.pages,_that.total);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationDoc> docs,  int limit,  int page,  int pages,  int total)  $default,) {final _that = this;
switch (_that) {
case _NotificationsData():
return $default(_that.docs,_that.limit,_that.page,_that.pages,_that.total);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationDoc> docs,  int limit,  int page,  int pages,  int total)?  $default,) {final _that = this;
switch (_that) {
case _NotificationsData() when $default != null:
return $default(_that.docs,_that.limit,_that.page,_that.pages,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationsData implements NotificationsData {
  const _NotificationsData({required final  List<NotificationDoc> docs, required this.limit, required this.page, required this.pages, required this.total}): _docs = docs;
  factory _NotificationsData.fromJson(Map<String, dynamic> json) => _$NotificationsDataFromJson(json);

 final  List<NotificationDoc> _docs;
@override List<NotificationDoc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override final  int limit;
@override final  int page;
@override final  int pages;
@override final  int total;

/// Create a copy of NotificationsData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationsDataCopyWith<_NotificationsData> get copyWith => __$NotificationsDataCopyWithImpl<_NotificationsData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationsDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationsData&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),limit,page,pages,total);

@override
String toString() {
  return 'NotificationsData(docs: $docs, limit: $limit, page: $page, pages: $pages, total: $total)';
}


}

/// @nodoc
abstract mixin class _$NotificationsDataCopyWith<$Res> implements $NotificationsDataCopyWith<$Res> {
  factory _$NotificationsDataCopyWith(_NotificationsData value, $Res Function(_NotificationsData) _then) = __$NotificationsDataCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationDoc> docs, int limit, int page, int pages, int total
});




}
/// @nodoc
class __$NotificationsDataCopyWithImpl<$Res>
    implements _$NotificationsDataCopyWith<$Res> {
  __$NotificationsDataCopyWithImpl(this._self, this._then);

  final _NotificationsData _self;
  final $Res Function(_NotificationsData) _then;

/// Create a copy of NotificationsData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? limit = null,Object? page = null,Object? pages = null,Object? total = null,}) {
  return _then(_NotificationsData(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<NotificationDoc>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
