import 'package:flutter/material.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/widgets/error_page.dart';

class BasePage extends StatelessWidget {
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
  final Widget Function(BuildContext context)? indicatorBuilder;
  final Widget Function(BuildContext context)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      final builder = errorBuilder;
      if (builder != null) {
        return builder(context);
      }
      return ErrorPage(
        errorMessage: getTextBeforeNewLine(error.toString()),
        onRetry: onRetry,
      );
    }

    if (isLoading) {
      final builder = indicatorBuilder;
      if (builder != null) {
        return builder(context);
      }
      return const Center(child: CircularProgressIndicator());
    }

    return child;
  }
}
