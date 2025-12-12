// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_controllers_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListControllersState {

 Ref get ref; ScrollOffsetController get scrollOffsetController; ItemScrollController get itemScrollController; PageController get pageController;
/// Create a copy of ListControllersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListControllersStateCopyWith<ListControllersState> get copyWith => _$ListControllersStateCopyWithImpl<ListControllersState>(this as ListControllersState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListControllersState&&(identical(other.ref, ref) || other.ref == ref)&&(identical(other.scrollOffsetController, scrollOffsetController) || other.scrollOffsetController == scrollOffsetController)&&(identical(other.itemScrollController, itemScrollController) || other.itemScrollController == itemScrollController)&&(identical(other.pageController, pageController) || other.pageController == pageController));
}


@override
int get hashCode => Object.hash(runtimeType,ref,scrollOffsetController,itemScrollController,pageController);

@override
String toString() {
  return 'ListControllersState(ref: $ref, scrollOffsetController: $scrollOffsetController, itemScrollController: $itemScrollController, pageController: $pageController)';
}


}

/// @nodoc
abstract mixin class $ListControllersStateCopyWith<$Res>  {
  factory $ListControllersStateCopyWith(ListControllersState value, $Res Function(ListControllersState) _then) = _$ListControllersStateCopyWithImpl;
@useResult
$Res call({
 Ref ref, ScrollOffsetController scrollOffsetController, ItemScrollController itemScrollController, PageController pageController
});




}
/// @nodoc
class _$ListControllersStateCopyWithImpl<$Res>
    implements $ListControllersStateCopyWith<$Res> {
  _$ListControllersStateCopyWithImpl(this._self, this._then);

  final ListControllersState _self;
  final $Res Function(ListControllersState) _then;

/// Create a copy of ListControllersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ref = null,Object? scrollOffsetController = null,Object? itemScrollController = null,Object? pageController = null,}) {
  return _then(_self.copyWith(
ref: null == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as Ref,scrollOffsetController: null == scrollOffsetController ? _self.scrollOffsetController : scrollOffsetController // ignore: cast_nullable_to_non_nullable
as ScrollOffsetController,itemScrollController: null == itemScrollController ? _self.itemScrollController : itemScrollController // ignore: cast_nullable_to_non_nullable
as ItemScrollController,pageController: null == pageController ? _self.pageController : pageController // ignore: cast_nullable_to_non_nullable
as PageController,
  ));
}

}


/// Adds pattern-matching-related methods to [ListControllersState].
extension ListControllersStatePatterns on ListControllersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListControllersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListControllersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListControllersState value)  $default,){
final _that = this;
switch (_that) {
case _ListControllersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListControllersState value)?  $default,){
final _that = this;
switch (_that) {
case _ListControllersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Ref ref,  ScrollOffsetController scrollOffsetController,  ItemScrollController itemScrollController,  PageController pageController)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListControllersState() when $default != null:
return $default(_that.ref,_that.scrollOffsetController,_that.itemScrollController,_that.pageController);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Ref ref,  ScrollOffsetController scrollOffsetController,  ItemScrollController itemScrollController,  PageController pageController)  $default,) {final _that = this;
switch (_that) {
case _ListControllersState():
return $default(_that.ref,_that.scrollOffsetController,_that.itemScrollController,_that.pageController);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Ref ref,  ScrollOffsetController scrollOffsetController,  ItemScrollController itemScrollController,  PageController pageController)?  $default,) {final _that = this;
switch (_that) {
case _ListControllersState() when $default != null:
return $default(_that.ref,_that.scrollOffsetController,_that.itemScrollController,_that.pageController);case _:
  return null;

}
}

}

/// @nodoc


class _ListControllersState extends ListControllersState {
  const _ListControllersState({required this.ref, required this.scrollOffsetController, required this.itemScrollController, required this.pageController}): super._();
  

@override final  Ref ref;
@override final  ScrollOffsetController scrollOffsetController;
@override final  ItemScrollController itemScrollController;
@override final  PageController pageController;

/// Create a copy of ListControllersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListControllersStateCopyWith<_ListControllersState> get copyWith => __$ListControllersStateCopyWithImpl<_ListControllersState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListControllersState&&(identical(other.ref, ref) || other.ref == ref)&&(identical(other.scrollOffsetController, scrollOffsetController) || other.scrollOffsetController == scrollOffsetController)&&(identical(other.itemScrollController, itemScrollController) || other.itemScrollController == itemScrollController)&&(identical(other.pageController, pageController) || other.pageController == pageController));
}


@override
int get hashCode => Object.hash(runtimeType,ref,scrollOffsetController,itemScrollController,pageController);

@override
String toString() {
  return 'ListControllersState(ref: $ref, scrollOffsetController: $scrollOffsetController, itemScrollController: $itemScrollController, pageController: $pageController)';
}


}

/// @nodoc
abstract mixin class _$ListControllersStateCopyWith<$Res> implements $ListControllersStateCopyWith<$Res> {
  factory _$ListControllersStateCopyWith(_ListControllersState value, $Res Function(_ListControllersState) _then) = __$ListControllersStateCopyWithImpl;
@override @useResult
$Res call({
 Ref ref, ScrollOffsetController scrollOffsetController, ItemScrollController itemScrollController, PageController pageController
});




}
/// @nodoc
class __$ListControllersStateCopyWithImpl<$Res>
    implements _$ListControllersStateCopyWith<$Res> {
  __$ListControllersStateCopyWithImpl(this._self, this._then);

  final _ListControllersState _self;
  final $Res Function(_ListControllersState) _then;

/// Create a copy of ListControllersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ref = null,Object? scrollOffsetController = null,Object? itemScrollController = null,Object? pageController = null,}) {
  return _then(_ListControllersState(
ref: null == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as Ref,scrollOffsetController: null == scrollOffsetController ? _self.scrollOffsetController : scrollOffsetController // ignore: cast_nullable_to_non_nullable
as ScrollOffsetController,itemScrollController: null == itemScrollController ? _self.itemScrollController : itemScrollController // ignore: cast_nullable_to_non_nullable
as ItemScrollController,pageController: null == pageController ? _self.pageController : pageController // ignore: cast_nullable_to_non_nullable
as PageController,
  ));
}


}

// dart format on
