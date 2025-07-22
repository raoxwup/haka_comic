import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';

mixin PaginationHandlerMixin<T extends StatefulWidget> on State<T> {
  final scrollController = ScrollController();
  final pagination = AppConf().pagination;
  bool _loading = false;

  Future<void> loadMore();

  void onScroll() {
    final position = scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    const threshold = 200.0; // 距离底部 200 像素内触发加载
    final distanceToBottom = position.maxScrollExtent - position.pixels;

    if (distanceToBottom <= threshold) {
      if (_loading) return;
      _loading = true;
      loadMore().whenComplete(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    if (!pagination) {
      scrollController.addListener(onScroll);
    }
  }

  @override
  void dispose() {
    if (!pagination) {
      scrollController
        ..removeListener(onScroll)
        ..dispose();
    }

    super.dispose();
  }
}
