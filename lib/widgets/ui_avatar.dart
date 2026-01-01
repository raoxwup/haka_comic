import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class UiAvatar extends StatelessWidget {
  const UiAvatar({super.key, this.source, required this.size});

  final ImageDetail? source;
  final double size;

  @override
  Widget build(BuildContext context) {
    return source == null
        ? CircleAvatar(
            radius: size / 2,
            backgroundColor: context.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const .all(5.0),
              child: Image.asset('assets/images/user.png'),
            ),
          )
        : UiImage(url: source!.url, width: size, height: size, shape: .circle);
  }
}
