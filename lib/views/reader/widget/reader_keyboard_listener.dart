import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/views/reader/reader_provider.dart';
import 'package:provider/provider.dart';

typedef KeyHandler = VoidCallback?;

class ReaderKeyboardListener extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Focus(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      includeSemantics: false,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (_ctrlKeys.contains(event.logicalKey)) {
          if (event is KeyUpEvent) {
            context.read<ReaderProvider>().isCtrlPressed = false;
          } else if (event is KeyDownEvent) {
            context.read<ReaderProvider>().isCtrlPressed = true;
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
