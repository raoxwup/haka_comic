import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/reader/state/initialize_reader_state.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/views/reader/state/reader_state.dart';

final readerStateProvider =
    NotifierProvider.autoDispose<ReaderStateNotifier, ReaderState>(
      ReaderStateNotifier.new,
    );

class ReaderStateNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    final initializeState = ref.watch(initializeReaderStateProvider);
    return ReaderState(
      id: initializeState.id,
      title: initializeState.title,
      chapters: initializeState.chapters,
      currentChapter:
          initializeState.currentChapter ?? initializeState.chapters.first,
      pageNo: initializeState.pageNo ?? 0,
      readMode: AppConf().readMode,
      showToolbar: false,
      isPageTurning: false,
      interval: AppConf().interval,
      isCtrlPressed: false,
      verticalListWidth: AppConf().verticalListWidthRatio,
    );
  }

  void openOrCloseToolbar() {
    state = state.copyWith(showToolbar: !state.showToolbar);
    SystemChrome.setEnabledSystemUIMode(
      state.showToolbar ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );
  }

  set readMode(ReadMode mode) {
    state = state.copyWith(readMode: mode);
    AppConf().readMode = mode;
  }
}

// 相当于一个占位符
final initializeReaderStateProvider =
    Provider.autoDispose<InitializeReaderState>((ref) {
      throw UnimplementedError(
        'initializeReaderStateProvider is not implemented.',
      );
    });
