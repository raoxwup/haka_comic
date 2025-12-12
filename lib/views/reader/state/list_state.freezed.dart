// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListState {

 bool get isCtrlPressed; ScrollPhysics get physics; double get verticalListWidthRatio;
/// Create a copy of ListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListStateCopyWith<ListState> get copyWith => _$ListStateCopyWithImpl<ListState>(this as ListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListState&&(identical(other.isCtrlPressed, isCtrlPressed) || other.isCtrlPressed == isCtrlPressed)&&(identical(other.physics, physics) || other.physics == physics)&&(identical(other.verticalListWidthRatio, verticalListWidthRatio) || other.verticalListWidthRatio == verticalListWidthRatio));
}


@override
int get hashCode => Object.hash(runtimeType,isCtrlPressed,physics,verticalListWidthRatio);

@override
String toString() {
  return 'ListState(isCtrlPressed: $isCtrlPressed, physics: $physics, verticalListWidthRatio: $verticalListWidthRatio)';
}


}

/// @nodoc
abstract mixin class $ListStateCopyWith<$Res>  {
  factory $ListStateCopyWith(ListState value, $Res Function(ListState) _then) = _$ListStateCopyWithImpl;
@useResult
$Res call({
 bool isCtrlPressed, ScrollPhysics physics, double verticalListWidthRatio
});




}
/// @nodoc
class _$ListStateCopyWithImpl<$Res>
    implements $ListStateCopyWith<$Res> {
  _$ListStateCopyWithImpl(this._self, this._then);

  final ListState _self;
  final $Res Function(ListState) _then;

/// Create a copy of ListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isCtrlPressed = null,Object? physics = null,Object? verticalListWidthRatio = null,}) {
  return _then(_self.copyWith(
isCtrlPressed: null == isCtrlPressed ? _self.isCtrlPressed : isCtrlPressed // ignore: cast_nullable_to_non_nullable
as bool,physics: null == physics ? _self.physics : physics // ignore: cast_nullable_to_non_nullable
as ScrollPhysics,verticalListWidthRatio: null == verticalListWidthRatio ? _self.verticalListWidthRatio : verticalListWidthRatio // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ListState].
extension ListStatePatterns on ListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListState value)  $default,){
final _that = this;
switch (_that) {
case _ListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListState value)?  $default,){
final _that = this;
switch (_that) {
case _ListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isCtrlPressed,  ScrollPhysics physics,  double verticalListWidthRatio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListState() when $default != null:
return $default(_that.isCtrlPressed,_that.physics,_that.verticalListWidthRatio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isCtrlPressed,  ScrollPhysics physics,  double verticalListWidthRatio)  $default,) {final _that = this;
switch (_that) {
case _ListState():
return $default(_that.isCtrlPressed,_that.physics,_that.verticalListWidthRatio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isCtrlPressed,  ScrollPhysics physics,  double verticalListWidthRatio)?  $default,) {final _that = this;
switch (_that) {
case _ListState() when $default != null:
return $default(_that.isCtrlPressed,_that.physics,_that.verticalListWidthRatio);case _:
  return null;

}
}

}

/// @nodoc


class _ListState implements ListState {
  const _ListState({required this.isCtrlPressed, required this.physics, required this.verticalListWidthRatio});
  

@override final  bool isCtrlPressed;
@override final  ScrollPhysics physics;
@override final  double verticalListWidthRatio;

/// Create a copy of ListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListStateCopyWith<_ListState> get copyWith => __$ListStateCopyWithImpl<_ListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListState&&(identical(other.isCtrlPressed, isCtrlPressed) || other.isCtrlPressed == isCtrlPressed)&&(identical(other.physics, physics) || other.physics == physics)&&(identical(other.verticalListWidthRatio, verticalListWidthRatio) || other.verticalListWidthRatio == verticalListWidthRatio));
}


@override
int get hashCode => Object.hash(runtimeType,isCtrlPressed,physics,verticalListWidthRatio);

@override
String toString() {
  return 'ListState(isCtrlPressed: $isCtrlPressed, physics: $physics, verticalListWidthRatio: $verticalListWidthRatio)';
}


}

/// @nodoc
abstract mixin class _$ListStateCopyWith<$Res> implements $ListStateCopyWith<$Res> {
  factory _$ListStateCopyWith(_ListState value, $Res Function(_ListState) _then) = __$ListStateCopyWithImpl;
@override @useResult
$Res call({
 bool isCtrlPressed, ScrollPhysics physics, double verticalListWidthRatio
});




}
/// @nodoc
class __$ListStateCopyWithImpl<$Res>
    implements _$ListStateCopyWith<$Res> {
  __$ListStateCopyWithImpl(this._self, this._then);

  final _ListState _self;
  final $Res Function(_ListState) _then;

/// Create a copy of ListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isCtrlPressed = null,Object? physics = null,Object? verticalListWidthRatio = null,}) {
  return _then(_ListState(
isCtrlPressed: null == isCtrlPressed ? _self.isCtrlPressed : isCtrlPressed // ignore: cast_nullable_to_non_nullable
as bool,physics: null == physics ? _self.physics : physics // ignore: cast_nullable_to_non_nullable
as ScrollPhysics,verticalListWidthRatio: null == verticalListWidthRatio ? _self.verticalListWidthRatio : verticalListWidthRatio // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
