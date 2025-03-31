import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';

class ErrorPage extends StatefulWidget {
  const ErrorPage({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final Function() onRetry;

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.errorMessage,
              style: context.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: widget.onRetry, child: const Text('重新加载')),
          TextButton(onPressed: context.pop, child: const Text('返回')),
        ],
      ),
    );
  }
}
