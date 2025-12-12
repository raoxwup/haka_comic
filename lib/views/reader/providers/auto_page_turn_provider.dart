import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/controller_provider.dart';
import 'package:haka_comic/views/reader/providers/images_provider.dart';
import 'package:haka_comic/views/reader/state/auto_page_turn_state.dart';

final autoPageTurnProvider =
    NotifierProvider.autoDispose<AutoPageTurnNotifier, AutoPageTurnState>(
      AutoPageTurnNotifier.new,
    );

class AutoPageTurnNotifier extends Notifier<AutoPageTurnState> {
  @override
  AutoPageTurnState build() {
    ref.onDispose(() => state.turnPageTimer?.cancel());

    return AutoPageTurnState(
      isPageTurning: false,
      interval: AppConf().interval,
      turnPageTimer: null,
    );
  }

  set interval(int interval) {
    state = state.copyWith(interval: interval);
    AppConf().interval = interval;
  }

  /// 开始定时翻页
  void startPageTurn(BuildContext context) {
    state.turnPageTimer?.cancel();
    final timer = Timer.periodic(Duration(seconds: state.interval), (timer) {
      final comicState = ref.read(comicReaderStateProvider(routerPayloadCache));
      final imagesAsyncValue = ref.read(
        imagesProvider(
          FetchChapterImagesPayload(
            id: comicState.id,
            order: comicState.chapter.order,
          ),
        ),
      );
      if (imagesAsyncValue.isLoading) return;
      ref.read(listControllersProvider.notifier).next(context);
    });
    state = state.copyWith(turnPageTimer: timer, isPageTurning: true);
  }

  /// 关闭定时翻页
  void stopPageTurn() {
    state.turnPageTimer?.cancel();
    state = state.copyWith(isPageTurning: false);
  }

  /// 更新定时翻页间隔
  void updateInterval(int interval, BuildContext context) {
    this.interval = interval;
    if (state.isPageTurning) {
      startPageTurn(context);
    }
  }
}
