import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class Empty extends StatelessWidget {
  const Empty({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.imageWidth = 120,
  });

  final double height;
  final double width;
  final double imageWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Image.asset('assets/images/icon_empty.png', width: imageWidth),
            Text('没有数据哦~', style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
