import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';

typedef KeyHandler = VoidCallback?;

class ReaderKeyboardListener extends ConsumerWidget {
  final Widget child;
  final Map<LogicalKeyboardKey, KeyHandler> handlers;

  const ReaderKeyboardListener({
    super.key,
    required this.child,
    this.handlers = const {},
  });

  static final Set<LogicalKeyboardKey> _ctrlKeys = {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.control,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(listStateProvider.notifier);
    return Focus(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      includeSemantics: false,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (_ctrlKeys.contains(event.logicalKey)) {
          if (event is KeyUpEvent) {
            notifier.isCtrlPressed = false;
          } else if (event is KeyDownEvent) {
            notifier.isCtrlPressed = true;
          }
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final handler = handlers[event.logicalKey];
          handler?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
