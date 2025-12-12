// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auto_page_turn_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AutoPageTurnState {

 bool get isPageTurning; Timer? get turnPageTimer; int get interval;
/// Create a copy of AutoPageTurnState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoPageTurnStateCopyWith<AutoPageTurnState> get copyWith => _$AutoPageTurnStateCopyWithImpl<AutoPageTurnState>(this as AutoPageTurnState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoPageTurnState&&(identical(other.isPageTurning, isPageTurning) || other.isPageTurning == isPageTurning)&&(identical(other.turnPageTimer, turnPageTimer) || other.turnPageTimer == turnPageTimer)&&(identical(other.interval, interval) || other.interval == interval));
}


@override
int get hashCode => Object.hash(runtimeType,isPageTurning,turnPageTimer,interval);

@override
String toString() {
  return 'AutoPageTurnState(isPageTurning: $isPageTurning, turnPageTimer: $turnPageTimer, interval: $interval)';
}


}

/// @nodoc
abstract mixin class $AutoPageTurnStateCopyWith<$Res>  {
  factory $AutoPageTurnStateCopyWith(AutoPageTurnState value, $Res Function(AutoPageTurnState) _then) = _$AutoPageTurnStateCopyWithImpl;
@useResult
$Res call({
 bool isPageTurning, Timer? turnPageTimer, int interval
});




}
/// @nodoc
class _$AutoPageTurnStateCopyWithImpl<$Res>
    implements $AutoPageTurnStateCopyWith<$Res> {
  _$AutoPageTurnStateCopyWithImpl(this._self, this._then);

  final AutoPageTurnState _self;
  final $Res Function(AutoPageTurnState) _then;

/// Create a copy of AutoPageTurnState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPageTurning = null,Object? turnPageTimer = freezed,Object? interval = null,}) {
  return _then(_self.copyWith(
isPageTurning: null == isPageTurning ? _self.isPageTurning : isPageTurning // ignore: cast_nullable_to_non_nullable
as bool,turnPageTimer: freezed == turnPageTimer ? _self.turnPageTimer : turnPageTimer // ignore: cast_nullable_to_non_nullable
as Timer?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AutoPageTurnState].
extension AutoPageTurnStatePatterns on AutoPageTurnState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoPageTurnState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoPageTurnState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoPageTurnState value)  $default,){
final _that = this;
switch (_that) {
case _AutoPageTurnState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoPageTurnState value)?  $default,){
final _that = this;
switch (_that) {
case _AutoPageTurnState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isPageTurning,  Timer? turnPageTimer,  int interval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoPageTurnState() when $default != null:
return $default(_that.isPageTurning,_that.turnPageTimer,_that.interval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isPageTurning,  Timer? turnPageTimer,  int interval)  $default,) {final _that = this;
switch (_that) {
case _AutoPageTurnState():
return $default(_that.isPageTurning,_that.turnPageTimer,_that.interval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isPageTurning,  Timer? turnPageTimer,  int interval)?  $default,) {final _that = this;
switch (_that) {
case _AutoPageTurnState() when $default != null:
return $default(_that.isPageTurning,_that.turnPageTimer,_that.interval);case _:
  return null;

}
}

}

/// @nodoc


class _AutoPageTurnState implements AutoPageTurnState {
  const _AutoPageTurnState({required this.isPageTurning, required this.turnPageTimer, required this.interval});
  

@override final  bool isPageTurning;
@override final  Timer? turnPageTimer;
@override final  int interval;

/// Create a copy of AutoPageTurnState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoPageTurnStateCopyWith<_AutoPageTurnState> get copyWith => __$AutoPageTurnStateCopyWithImpl<_AutoPageTurnState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoPageTurnState&&(identical(other.isPageTurning, isPageTurning) || other.isPageTurning == isPageTurning)&&(identical(other.turnPageTimer, turnPageTimer) || other.turnPageTimer == turnPageTimer)&&(identical(other.interval, interval) || other.interval == interval));
}


@override
int get hashCode => Object.hash(runtimeType,isPageTurning,turnPageTimer,interval);

@override
String toString() {
  return 'AutoPageTurnState(isPageTurning: $isPageTurning, turnPageTimer: $turnPageTimer, interval: $interval)';
}


}

/// @nodoc
abstract mixin class _$AutoPageTurnStateCopyWith<$Res> implements $AutoPageTurnStateCopyWith<$Res> {
  factory _$AutoPageTurnStateCopyWith(_AutoPageTurnState value, $Res Function(_AutoPageTurnState) _then) = __$AutoPageTurnStateCopyWithImpl;
@override @useResult
$Res call({
 bool isPageTurning, Timer? turnPageTimer, int interval
});




}
/// @nodoc
class __$AutoPageTurnStateCopyWithImpl<$Res>
    implements _$AutoPageTurnStateCopyWith<$Res> {
  __$AutoPageTurnStateCopyWithImpl(this._self, this._then);

  final _AutoPageTurnState _self;
  final $Res Function(_AutoPageTurnState) _then;

/// Create a copy of AutoPageTurnState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPageTurning = null,Object? turnPageTimer = freezed,Object? interval = null,}) {
  return _then(_AutoPageTurnState(
isPageTurning: null == isPageTurning ? _self.isPageTurning : isPageTurning // ignore: cast_nullable_to_non_nullable
as bool,turnPageTimer: freezed == turnPageTimer ? _self.turnPageTimer : turnPageTimer // ignore: cast_nullable_to_non_nullable
as Timer?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
