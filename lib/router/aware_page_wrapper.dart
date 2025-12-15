import 'package:flutter/material.dart';

typedef RouteAwarePageBuilder =
    Widget Function(BuildContext context, bool completed);

class RouteAwarePageWrapper extends StatefulWidget {
  final RouteAwarePageBuilder builder;
  final bool shouldRebuildOnCompleted;

  const RouteAwarePageWrapper({
    super.key,
    required this.builder,
    this.shouldRebuildOnCompleted = true,
  });

  @override
  State<RouteAwarePageWrapper> createState() => _RouteAwarePageWrapperState();
}

class _RouteAwarePageWrapperState extends State<RouteAwarePageWrapper> {
  bool _completed = false;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation == null) {
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        _routeAnimation = route.animation;

        if (_routeAnimation!.status == AnimationStatus.completed) {
          _markCompleted();
        } else {
          _routeAnimation!.addStatusListener(_handleRouteAnimationStatus);
        }
      } else {
        _markCompleted();
      }
    }
  }

  void _handleRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _markCompleted();
      _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    }
  }

  void _markCompleted() {
    if (_completed) return;

    if (mounted) {
      if (widget.shouldRebuildOnCompleted) {
        setState(() => _completed = true);
      } else {
        _completed = true;
      }
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _completed);
  }
}
