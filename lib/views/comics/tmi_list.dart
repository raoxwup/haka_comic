import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/settings/browse_mode.dart';

class TMIList extends StatelessWidget {
  const TMIList({
    super.key,
    this.controller,
    this.itemCount,
    required this.itemBuilder,
    this.pageSelectorBuilder,
  });

  /// 滑动控制器
  final ScrollController? controller;

  final int? itemCount;

  final NullableIndexedWidgetBuilder itemBuilder;

  final Widget Function(BuildContext)? pageSelectorBuilder;

  /// 简洁模式？
  bool get isSimpleMode => AppConf().comicBlockMode == ComicBlockMode.simple;

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    final gridDelegate =
        isSimpleMode
            ? SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  UiMode.m1(context)
                      ? 130
                      : UiMode.m2(context)
                      ? 135
                      : 140,
              mainAxisSpacing: 2,
              crossAxisSpacing: 3,
              childAspectRatio: 1 / 1.66,
            )
            : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  UiMode.m1(context)
                      ? width
                      : UiMode.m2(context)
                      ? width / 2
                      : width / 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 2.5,
            );

    return CustomScrollView(
      controller: controller,
      slivers: [
        if (pageSelectorBuilder != null) pageSelectorBuilder!(context),
        SliverGrid.builder(
          gridDelegate: gridDelegate,
          itemBuilder: itemBuilder,
          itemCount: itemCount,
        ),
        if (pageSelectorBuilder != null) pageSelectorBuilder!(context),
      ],
    );
  }
}
