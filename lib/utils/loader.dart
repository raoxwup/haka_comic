import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';

class Loader {
  static bool isShowing = false;

  static void show(BuildContext context) {
    if (isShowing) return;
    isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (context.canPop() && isShowing) {
      isShowing = false;
      context.pop();
    }
  }
}
