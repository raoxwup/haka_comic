import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

part 'list_controllers_state.freezed.dart';

@freezed
abstract class ListControllersState with _$ListControllersState {
  const ListControllersState._();

  const factory ListControllersState({
    required Ref ref,
    required ScrollOffsetController scrollOffsetController,
    required ItemScrollController itemScrollController,
    required PageController pageController,
  }) = _ListControllersState;
}
