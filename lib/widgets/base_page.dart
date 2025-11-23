import 'package:flutter/material.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/widgets/error_page.dart';

class BasePage extends StatefulWidget {
  const BasePage({
    super.key,
    this.error,
    required this.isLoading,
    required this.onRetry,
    required this.child,
    this.indicatorBuilder,
    this.errorBuilder,
  });

  final Object? error;

  final bool isLoading;

  final VoidCallback onRetry;

  final Widget child;

  final Widget Function(BuildContext)? indicatorBuilder;

  final Widget Function(BuildContext)? errorBuilder;

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  @override
  Widget build(BuildContext context) {
    return widget.error != null
        ? widget.errorBuilder != null
              ? widget.errorBuilder!(context)
              : ErrorPage(
                  errorMessage: getTextBeforeNewLine(widget.error.toString()),
                  onRetry: widget.onRetry,
                )
        : widget.isLoading
        ? widget.indicatorBuilder != null
              ? widget.indicatorBuilder!(context)
              : const Center(child: CircularProgressIndicator())
        : widget.child;
  }
}
