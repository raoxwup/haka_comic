import 'package:freezed_annotation/freezed_annotation.dart';
import '../state/read_mode.dart';
import 'package:haka_comic/network/models.dart';

part 'reader_state.freezed.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    required String id,
    required String title,
    required List<Chapter> chapters,
    required Chapter currentChapter,
    required int pageNo,
    required ReadMode readMode,
    required bool showToolbar,
    required bool isPageTurning,
    required int interval,
    required bool isCtrlPressed,
    required double verticalListWidth,
  }) = _ReaderState;
}
