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

// dart format on
