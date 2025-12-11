// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderState {

 String get id; String get title; List<Chapter> get chapters; Chapter get currentChapter; int get pageNo; ReadMode get readMode; bool get showToolbar; bool get isPageTurning; int get interval; bool get isCtrlPressed; double get verticalListWidth;
/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderStateCopyWith<ReaderState> get copyWith => _$ReaderStateCopyWithImpl<ReaderState>(this as ReaderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&(identical(other.currentChapter, currentChapter) || other.currentChapter == currentChapter)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.readMode, readMode) || other.readMode == readMode)&&(identical(other.showToolbar, showToolbar) || other.showToolbar == showToolbar)&&(identical(other.isPageTurning, isPageTurning) || other.isPageTurning == isPageTurning)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.isCtrlPressed, isCtrlPressed) || other.isCtrlPressed == isCtrlPressed)&&(identical(other.verticalListWidth, verticalListWidth) || other.verticalListWidth == verticalListWidth));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(chapters),currentChapter,pageNo,readMode,showToolbar,isPageTurning,interval,isCtrlPressed,verticalListWidth);

@override
String toString() {
  return 'ReaderState(id: $id, title: $title, chapters: $chapters, currentChapter: $currentChapter, pageNo: $pageNo, readMode: $readMode, showToolbar: $showToolbar, isPageTurning: $isPageTurning, interval: $interval, isCtrlPressed: $isCtrlPressed, verticalListWidth: $verticalListWidth)';
}


}

/// @nodoc
abstract mixin class $ReaderStateCopyWith<$Res>  {
  factory $ReaderStateCopyWith(ReaderState value, $Res Function(ReaderState) _then) = _$ReaderStateCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<Chapter> chapters, Chapter currentChapter, int pageNo, ReadMode readMode, bool showToolbar, bool isPageTurning, int interval, bool isCtrlPressed, double verticalListWidth
});




}
/// @nodoc
class _$ReaderStateCopyWithImpl<$Res>
    implements $ReaderStateCopyWith<$Res> {
  _$ReaderStateCopyWithImpl(this._self, this._then);

  final ReaderState _self;
  final $Res Function(ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? chapters = null,Object? currentChapter = null,Object? pageNo = null,Object? readMode = null,Object? showToolbar = null,Object? isPageTurning = null,Object? interval = null,Object? isCtrlPressed = null,Object? verticalListWidth = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,currentChapter: null == currentChapter ? _self.currentChapter : currentChapter // ignore: cast_nullable_to_non_nullable
as Chapter,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,readMode: null == readMode ? _self.readMode : readMode // ignore: cast_nullable_to_non_nullable
as ReadMode,showToolbar: null == showToolbar ? _self.showToolbar : showToolbar // ignore: cast_nullable_to_non_nullable
as bool,isPageTurning: null == isPageTurning ? _self.isPageTurning : isPageTurning // ignore: cast_nullable_to_non_nullable
as bool,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,isCtrlPressed: null == isCtrlPressed ? _self.isCtrlPressed : isCtrlPressed // ignore: cast_nullable_to_non_nullable
as bool,verticalListWidth: null == verticalListWidth ? _self.verticalListWidth : verticalListWidth // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ReaderState].
extension ReaderStatePatterns on ReaderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReaderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReaderState value)  $default,){
final _that = this;
switch (_that) {
case _ReaderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReaderState value)?  $default,){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<Chapter> chapters,  Chapter currentChapter,  int pageNo,  ReadMode readMode,  bool showToolbar,  bool isPageTurning,  int interval,  bool isCtrlPressed,  double verticalListWidth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.id,_that.title,_that.chapters,_that.currentChapter,_that.pageNo,_that.readMode,_that.showToolbar,_that.isPageTurning,_that.interval,_that.isCtrlPressed,_that.verticalListWidth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<Chapter> chapters,  Chapter currentChapter,  int pageNo,  ReadMode readMode,  bool showToolbar,  bool isPageTurning,  int interval,  bool isCtrlPressed,  double verticalListWidth)  $default,) {final _that = this;
switch (_that) {
case _ReaderState():
return $default(_that.id,_that.title,_that.chapters,_that.currentChapter,_that.pageNo,_that.readMode,_that.showToolbar,_that.isPageTurning,_that.interval,_that.isCtrlPressed,_that.verticalListWidth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<Chapter> chapters,  Chapter currentChapter,  int pageNo,  ReadMode readMode,  bool showToolbar,  bool isPageTurning,  int interval,  bool isCtrlPressed,  double verticalListWidth)?  $default,) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.id,_that.title,_that.chapters,_that.currentChapter,_that.pageNo,_that.readMode,_that.showToolbar,_that.isPageTurning,_that.interval,_that.isCtrlPressed,_that.verticalListWidth);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderState implements ReaderState {
  const _ReaderState({required this.id, required this.title, required final  List<Chapter> chapters, required this.currentChapter, required this.pageNo, required this.readMode, required this.showToolbar, required this.isPageTurning, required this.interval, required this.isCtrlPressed, required this.verticalListWidth}): _chapters = chapters;
  

@override final  String id;
@override final  String title;
 final  List<Chapter> _chapters;
@override List<Chapter> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}

@override final  Chapter currentChapter;
@override final  int pageNo;
@override final  ReadMode readMode;
@override final  bool showToolbar;
@override final  bool isPageTurning;
@override final  int interval;
@override final  bool isCtrlPressed;
@override final  double verticalListWidth;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderStateCopyWith<_ReaderState> get copyWith => __$ReaderStateCopyWithImpl<_ReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderState&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&(identical(other.currentChapter, currentChapter) || other.currentChapter == currentChapter)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.readMode, readMode) || other.readMode == readMode)&&(identical(other.showToolbar, showToolbar) || other.showToolbar == showToolbar)&&(identical(other.isPageTurning, isPageTurning) || other.isPageTurning == isPageTurning)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.isCtrlPressed, isCtrlPressed) || other.isCtrlPressed == isCtrlPressed)&&(identical(other.verticalListWidth, verticalListWidth) || other.verticalListWidth == verticalListWidth));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_chapters),currentChapter,pageNo,readMode,showToolbar,isPageTurning,interval,isCtrlPressed,verticalListWidth);

@override
String toString() {
  return 'ReaderState(id: $id, title: $title, chapters: $chapters, currentChapter: $currentChapter, pageNo: $pageNo, readMode: $readMode, showToolbar: $showToolbar, isPageTurning: $isPageTurning, interval: $interval, isCtrlPressed: $isCtrlPressed, verticalListWidth: $verticalListWidth)';
}


}

/// @nodoc
abstract mixin class _$ReaderStateCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory _$ReaderStateCopyWith(_ReaderState value, $Res Function(_ReaderState) _then) = __$ReaderStateCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<Chapter> chapters, Chapter currentChapter, int pageNo, ReadMode readMode, bool showToolbar, bool isPageTurning, int interval, bool isCtrlPressed, double verticalListWidth
});




}
/// @nodoc
class __$ReaderStateCopyWithImpl<$Res>
    implements _$ReaderStateCopyWith<$Res> {
  __$ReaderStateCopyWithImpl(this._self, this._then);

  final _ReaderState _self;
  final $Res Function(_ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? chapters = null,Object? currentChapter = null,Object? pageNo = null,Object? readMode = null,Object? showToolbar = null,Object? isPageTurning = null,Object? interval = null,Object? isCtrlPressed = null,Object? verticalListWidth = null,}) {
  return _then(_ReaderState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,currentChapter: null == currentChapter ? _self.currentChapter : currentChapter // ignore: cast_nullable_to_non_nullable
as Chapter,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,readMode: null == readMode ? _self.readMode : readMode // ignore: cast_nullable_to_non_nullable
as ReadMode,showToolbar: null == showToolbar ? _self.showToolbar : showToolbar // ignore: cast_nullable_to_non_nullable
as bool,isPageTurning: null == isPageTurning ? _self.isPageTurning : isPageTurning // ignore: cast_nullable_to_non_nullable
as bool,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,isCtrlPressed: null == isCtrlPressed ? _self.isCtrlPressed : isCtrlPressed // ignore: cast_nullable_to_non_nullable
as bool,verticalListWidth: null == verticalListWidth ? _self.verticalListWidth : verticalListWidth // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
