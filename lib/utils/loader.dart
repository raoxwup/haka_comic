import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/utils/extension.dart';

class Loader {
  static bool isShowing = false;
  static OverlayEntry? _entry;

  static void show() {
    if (isShowing) return;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    isShowing = true;
    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    if (!isShowing) return;
    isShowing = false;
    _entry?.remove();
    _entry = null;
  }
}
