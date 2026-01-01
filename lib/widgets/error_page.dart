import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';

class ErrorPage extends StatefulWidget {
  const ErrorPage({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.canPop = false,
  });

  final String errorMessage;
  final Function() onRetry;
  final bool canPop;

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
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium,
            ),
          ),
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: widget.onRetry, child: const Text('重新加载')),
              if (widget.canPop && context.canPop())
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('返回'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
