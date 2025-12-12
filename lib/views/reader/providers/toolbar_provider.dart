import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolbarProvider = NotifierProvider.autoDispose<ToolbarNotifier, bool>(
  ToolbarNotifier.new,
);

class ToolbarNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void openOrCloseToolbar() {
    Future.microtask(() {
      state = !state;
      SystemChrome.setEnabledSystemUIMode(
        state ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
      );
    });
  }
}
