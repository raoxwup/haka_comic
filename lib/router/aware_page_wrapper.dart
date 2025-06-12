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
  late bool _completed;
  Animation? _routeAnimation;

  @override
  void initState() {
    super.initState();
    _completed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupRouteListener());
  }

  void _setupRouteListener() {
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeAnimation = route.animation;
      // 检查初始状态
      if (_routeAnimation?.status == AnimationStatus.completed) {
        _markCompleted();
      } else {
        _routeAnimation?.addStatusListener(_handleRouteAnimationStatus);
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
    if (!_completed && widget.shouldRebuildOnCompleted) {
      setState(() => _completed = true);
    } else {
      _completed = true;
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
