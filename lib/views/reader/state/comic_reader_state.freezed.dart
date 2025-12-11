// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_reader_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComicReaderState {

 String get id; String get title; List<Chapter> get chapters; Chapter get chapter; int get pageNo;
/// Create a copy of ComicReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicReaderStateCopyWith<ComicReaderState> get copyWith => _$ComicReaderStateCopyWithImpl<ComicReaderState>(this as ComicReaderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicReaderState&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(chapters),chapter,pageNo);

@override
String toString() {
  return 'ComicReaderState(id: $id, title: $title, chapters: $chapters, chapter: $chapter, pageNo: $pageNo)';
}


}

/// @nodoc
abstract mixin class $ComicReaderStateCopyWith<$Res>  {
  factory $ComicReaderStateCopyWith(ComicReaderState value, $Res Function(ComicReaderState) _then) = _$ComicReaderStateCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<Chapter> chapters, Chapter chapter, int pageNo
});




}
/// @nodoc
class _$ComicReaderStateCopyWithImpl<$Res>
    implements $ComicReaderStateCopyWith<$Res> {
  _$ComicReaderStateCopyWithImpl(this._self, this._then);

  final ComicReaderState _self;
  final $Res Function(ComicReaderState) _then;

/// Create a copy of ComicReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? chapters = null,Object? chapter = null,Object? pageNo = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as Chapter,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicReaderState].
extension ComicReaderStatePatterns on ComicReaderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicReaderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicReaderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicReaderState value)  $default,){
final _that = this;
switch (_that) {
case _ComicReaderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicReaderState value)?  $default,){
final _that = this;
switch (_that) {
case _ComicReaderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<Chapter> chapters,  Chapter chapter,  int pageNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicReaderState() when $default != null:
return $default(_that.id,_that.title,_that.chapters,_that.chapter,_that.pageNo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<Chapter> chapters,  Chapter chapter,  int pageNo)  $default,) {final _that = this;
switch (_that) {
case _ComicReaderState():
return $default(_that.id,_that.title,_that.chapters,_that.chapter,_that.pageNo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<Chapter> chapters,  Chapter chapter,  int pageNo)?  $default,) {final _that = this;
switch (_that) {
case _ComicReaderState() when $default != null:
return $default(_that.id,_that.title,_that.chapters,_that.chapter,_that.pageNo);case _:
  return null;

}
}

}

/// @nodoc


class _ComicReaderState extends ComicReaderState {
  const _ComicReaderState({required this.id, required this.title, required final  List<Chapter> chapters, required this.chapter, required this.pageNo}): _chapters = chapters,super._();
  

@override final  String id;
@override final  String title;
 final  List<Chapter> _chapters;
@override List<Chapter> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}

@override final  Chapter chapter;
@override final  int pageNo;

/// Create a copy of ComicReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicReaderStateCopyWith<_ComicReaderState> get copyWith => __$ComicReaderStateCopyWithImpl<_ComicReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicReaderState&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_chapters),chapter,pageNo);

@override
String toString() {
  return 'ComicReaderState(id: $id, title: $title, chapters: $chapters, chapter: $chapter, pageNo: $pageNo)';
}


}

/// @nodoc
abstract mixin class _$ComicReaderStateCopyWith<$Res> implements $ComicReaderStateCopyWith<$Res> {
  factory _$ComicReaderStateCopyWith(_ComicReaderState value, $Res Function(_ComicReaderState) _then) = __$ComicReaderStateCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<Chapter> chapters, Chapter chapter, int pageNo
});




}
/// @nodoc
class __$ComicReaderStateCopyWithImpl<$Res>
    implements _$ComicReaderStateCopyWith<$Res> {
  __$ComicReaderStateCopyWithImpl(this._self, this._then);

  final _ComicReaderState _self;
  final $Res Function(_ComicReaderState) _then;

/// Create a copy of ComicReaderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? chapters = null,Object? chapter = null,Object? pageNo = null,}) {
  return _then(_ComicReaderState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as Chapter,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
