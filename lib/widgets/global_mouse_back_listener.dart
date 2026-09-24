import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

class GlobalMouseBackListener extends StatelessWidget {
  const GlobalMouseBackListener({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.enabled = true,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;

  void _handlePointerDown(PointerDownEvent event) {
    if (!enabled || event.kind != PointerDeviceKind.mouse) {
      return;
    }
    if ((event.buttons & kBackMouseButton) == 0) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    unawaited(navigator.maybePop());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }
}
