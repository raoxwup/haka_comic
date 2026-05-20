import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class Empty extends StatelessWidget {
  const Empty({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.imageWidth = 120,
    this.imageUrl = 'assets/images/icon_empty.png',
    this.onRefresh,
  });

  final double height;
  final double width;
  final double imageWidth;
  final String imageUrl;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: width,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Image.asset(imageUrl, width: imageWidth),
            Text('没有数据哦~', style: context.textTheme.bodySmall),
            if (onRefresh != null)
              FilledButton.tonalIcon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
          ],
        ),
      ),
    );
  }
}
