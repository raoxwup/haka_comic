import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/ui.dart';

const _sideSheetTransitionDuration = Duration(milliseconds: 300);
const _sideSheetDismissGuardDuration = Duration(milliseconds: 350);

Page<dynamic> buildSideSheetRoutePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    opaque: false,
    transitionDuration: _sideSheetTransitionDuration,
    reverseTransitionDuration: _sideSheetTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _SideSheetTransition(animation: animation, child: child);
    },
    child: child,
  );
}

class _SideSheetTransition extends StatefulWidget {
  const _SideSheetTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_SideSheetTransition> createState() => _SideSheetTransitionState();
}

class _SideSheetTransitionState extends State<_SideSheetTransition> {
  bool _closing = false;

  void _close() {
    if (_closing) return;

    final router = GoRouter.of(context);
    if (!router.canPop()) return;

    setState(() => _closing = true);

    try {
      router.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _closing = false);
      }
      return;
    }

    Future<void>.delayed(_sideSheetDismissGuardDuration, () {
      if (!mounted) return;
      setState(() => _closing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedModalBarrier(
            color: ColorTween(
              begin: Colors.transparent,
              end: Colors.black54,
            ).animate(curvedAnimation),
            dismissible: !_closing,
            semanticsLabel: MaterialLocalizations.of(
              context,
            ).modalBarrierDismissLabel,
            onDismiss: _close,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: _SideSheetSurface(child: widget.child),
          ),
        ),
      ],
    );
  }
}

class _SideSheetSurface extends StatelessWidget {
  const _SideSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final material = Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: UiMode.m1(context) ? 0 : 4,
      child: child,
    );

    if (UiMode.m1(context)) {
      return SizedBox.expand(child: material);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthFactor = UiMode.m2(context) ? 0.72 : 0.5;
        final width = (constraints.maxWidth * widthFactor)
            .clamp(420.0, 720.0)
            .toDouble();

        return SizedBox(width: width, child: material);
      },
    );
  }
}
