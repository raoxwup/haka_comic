import 'package:flutter/material.dart';

class LoadingWrapper extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final CircularProgressIndicator? progressIndicator;

  const LoadingWrapper({
    super.key,
    required this.child,
    required this.isLoading,
    this.progressIndicator,
  });

  @override
  State<LoadingWrapper> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.isLoading
        ? widget.progressIndicator ?? const CircularProgressIndicator()
        : widget.child;
  }
}
