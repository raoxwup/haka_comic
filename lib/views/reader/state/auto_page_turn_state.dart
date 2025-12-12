import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auto_page_turn_state.freezed.dart';

@freezed
abstract class AutoPageTurnState with _$AutoPageTurnState {
  const factory AutoPageTurnState({
    required bool isPageTurning,
    required Timer? turnPageTimer,
    required int interval,
  }) = _AutoPageTurnState;
}
