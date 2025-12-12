import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_state.freezed.dart';

@freezed
abstract class ListState with _$ListState {
  const factory ListState({
    required bool isCtrlPressed,
    required ScrollPhysics physics,
    required double verticalListWidthRatio,
  }) = _ListState;
}
