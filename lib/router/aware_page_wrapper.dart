import 'package:flutter/material.dart';

class RouteAwarePageWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRouteAnimationCompleted;

  const RouteAwarePageWrapper({
    super.key,
    required this.child,
    this.onRouteAnimationCompleted,
  });

  @override
  State<RouteAwarePageWrapper> createState() => _RouteAwarePageWrapperState();
}

class _RouteAwarePageWrapperState extends State<RouteAwarePageWrapper> {
  Animation? _routeAnimation;

  @override
  void initState() {
    super.initState();
    // 确保在页面构建完成后获取路由
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupRouteListener());
  }

  void _setupRouteListener() {
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeAnimation = route.animation;
      // 确保触发回调
      if (_routeAnimation?.status == AnimationStatus.completed) {
        widget.onRouteAnimationCompleted?.call();
      } else {
        _routeAnimation?.addStatusListener(_handleRouteAnimationStatus);
      }
    }
  }

  void _handleRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 触发回调，通知子页面动画完成
      widget.onRouteAnimationCompleted?.call();
      // 移除监听器避免重复执行
      _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
