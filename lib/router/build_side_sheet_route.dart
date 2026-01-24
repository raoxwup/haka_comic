import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/ui.dart';

Page<dynamic> buildSideSheetRoutePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: curvedAnimation,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
                child: Container(color: Colors.black54),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: UiMode.m1(context)
                  ? Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: child,
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Material(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        elevation: 4,
                        child: child,
                      ),
                    ),
            ),
          ),
        ],
      );
    },
    child: child,
  );
}
