import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';

typedef KeyHandler = VoidCallback?;

class ReaderKeyboardListener extends StatefulWidget {
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
  State<ReaderKeyboardListener> createState() => _ReaderKeyboardListenerState();
}

class _ReaderKeyboardListenerState extends State<ReaderKeyboardListener> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      includeSemantics: false,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (ReaderKeyboardListener._ctrlKeys.contains(event.logicalKey)) {
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
          final handler = widget.handlers[event.logicalKey];
          handler?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
