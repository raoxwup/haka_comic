import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';

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
            context.stateReader.isCtrlPressed = false;
            context.stateReader.physics = const BouncingScrollPhysics();
          } else if (event is KeyDownEvent) {
            context.stateReader.isCtrlPressed = true;
            context.stateReader.physics = const NeverScrollableScrollPhysics();
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
