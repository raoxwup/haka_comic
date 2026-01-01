import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/comic_details/title_box.dart';

class DescriptionBox extends StatelessWidget {
  const DescriptionBox({
    super.key,
    required this.description,
  });

  final String? description;

  @override
  Widget build(BuildContext context) {
    return TitleBox(
      title: '简介',
      builder: (context) {
        return Text(
          description ?? '暂无简介',
          style: context.textTheme.bodyMedium,
        );
      },
    );
  }
}
