import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';

final readModeProvider =
    NotifierProvider.autoDispose<ReadModeNotifier, ReadMode>(
      ReadModeNotifier.new,
    );

class ReadModeNotifier extends Notifier<ReadMode> {
  @override
  build() {
    return AppConf().readMode;
  }

  set readMode(ReadMode mode) => state = mode;
}
