import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class CommonPaginationFooter extends StatelessWidget {
  const CommonPaginationFooter({super.key, required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: loading
              ? CircularProgressIndicator(
                  constraints: BoxConstraints.tight(const Size(28, 28)),
                  strokeWidth: 3,
                )
              : Text('没有更多数据了', style: context.textTheme.bodySmall),
        ),
      ),
    );
  }
}
