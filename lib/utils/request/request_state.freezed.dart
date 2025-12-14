// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RequestState<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RequestState<$T>()';
}


}

/// @nodoc
class $RequestStateCopyWith<T,$Res>  {
$RequestStateCopyWith(RequestState<T> _, $Res Function(RequestState<T>) __);
}


/// Adds pattern-matching-related methods to [RequestState].
extension RequestStatePatterns<T> on RequestState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RequestInitial<T> value)?  initial,TResult Function( RequestLoading<T> value)?  loading,TResult Function( RequestSuccess<T> value)?  success,TResult Function( RequestError<T> value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RequestInitial() when initial != null:
return initial(_that);case RequestLoading() when loading != null:
return loading(_that);case RequestSuccess() when success != null:
return success(_that);case RequestError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RequestInitial<T> value)  initial,required TResult Function( RequestLoading<T> value)  loading,required TResult Function( RequestSuccess<T> value)  success,required TResult Function( RequestError<T> value)  error,}){
final _that = this;
switch (_that) {
case RequestInitial():
return initial(_that);case RequestLoading():
return loading(_that);case RequestSuccess():
return success(_that);case RequestError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RequestInitial<T> value)?  initial,TResult? Function( RequestLoading<T> value)?  loading,TResult? Function( RequestSuccess<T> value)?  success,TResult? Function( RequestError<T> value)?  error,}){
final _that = this;
switch (_that) {
case RequestInitial() when initial != null:
return initial(_that);case RequestLoading() when loading != null:
return loading(_that);case RequestSuccess() when success != null:
return success(_that);case RequestError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( T data)?  success,TResult Function( Object error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RequestInitial() when initial != null:
return initial();case RequestLoading() when loading != null:
return loading();case RequestSuccess() when success != null:
return success(_that.data);case RequestError() when error != null:
return error(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( T data)  success,required TResult Function( Object error)  error,}) {final _that = this;
switch (_that) {
case RequestInitial():
return initial();case RequestLoading():
return loading();case RequestSuccess():
return success(_that.data);case RequestError():
return error(_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( T data)?  success,TResult? Function( Object error)?  error,}) {final _that = this;
switch (_that) {
case RequestInitial() when initial != null:
return initial();case RequestLoading() when loading != null:
return loading();case RequestSuccess() when success != null:
return success(_that.data);case RequestError() when error != null:
return error(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class RequestInitial<T> extends RequestState<T> {
  const RequestInitial(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestInitial<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RequestState<$T>.initial()';
}


}




/// @nodoc


class RequestLoading<T> extends RequestState<T> {
  const RequestLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestLoading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RequestState<$T>.loading()';
}


}




/// @nodoc


class RequestSuccess<T> extends RequestState<T> {
  const RequestSuccess(this.data): super._();
  

 final  T data;

/// Create a copy of RequestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestSuccessCopyWith<T, RequestSuccess<T>> get copyWith => _$RequestSuccessCopyWithImpl<T, RequestSuccess<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestSuccess<T>&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'RequestState<$T>.success(data: $data)';
}


}

/// @nodoc
abstract mixin class $RequestSuccessCopyWith<T,$Res> implements $RequestStateCopyWith<T, $Res> {
  factory $RequestSuccessCopyWith(RequestSuccess<T> value, $Res Function(RequestSuccess<T>) _then) = _$RequestSuccessCopyWithImpl;
@useResult
$Res call({
 T data
});




}
/// @nodoc
class _$RequestSuccessCopyWithImpl<T,$Res>
    implements $RequestSuccessCopyWith<T, $Res> {
  _$RequestSuccessCopyWithImpl(this._self, this._then);

  final RequestSuccess<T> _self;
  final $Res Function(RequestSuccess<T>) _then;

/// Create a copy of RequestState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(RequestSuccess<T>(
freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class RequestError<T> extends RequestState<T> {
  const RequestError(this.error): super._();
  

 final  Object error;

/// Create a copy of RequestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestErrorCopyWith<T, RequestError<T>> get copyWith => _$RequestErrorCopyWithImpl<T, RequestError<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestError<T>&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'RequestState<$T>.error(error: $error)';
}


}

/// @nodoc
abstract mixin class $RequestErrorCopyWith<T,$Res> implements $RequestStateCopyWith<T, $Res> {
  factory $RequestErrorCopyWith(RequestError<T> value, $Res Function(RequestError<T>) _then) = _$RequestErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$RequestErrorCopyWithImpl<T,$Res>
    implements $RequestErrorCopyWith<T, $Res> {
  _$RequestErrorCopyWithImpl(this._self, this._then);

  final RequestError<T> _self;
  final $Res Function(RequestError<T>) _then;

/// Create a copy of RequestState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(RequestError<T>(
null == error ? _self.error : error ,
  ));
}


}

// dart format on
