import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/reader/state/list_state.dart';

final listStateProvider =
    NotifierProvider.autoDispose<ListStateNotifier, ListState>(
      ListStateNotifier.new,
    );

class ListStateNotifier extends Notifier<ListState> {
  @override
  ListState build() {
    return ListState(
      isCtrlPressed: false,
      physics: const BouncingScrollPhysics(),
      verticalListWidthRatio: AppConf().verticalListWidthRatio,
    );
  }

  set physics(ScrollPhysics physics) =>
      state = state.copyWith(physics: physics);

  set isCtrlPressed(bool isCtrlPressed) =>
      state = state.copyWith(isCtrlPressed: isCtrlPressed);

  set verticalListWidthRatio(double ratio) {
    state = state.copyWith(verticalListWidthRatio: ratio);
    AppConf().verticalListWidthRatio = ratio;
  }
}
