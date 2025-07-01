import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/reader/reader.dart';

mixin ComicListMixin<T extends StatefulWidget> on State<T> {
  @override
  dispose() {
    _preloadDebounceTimer?.cancel();
    super.dispose();
  }

  /// 已加载图片索引 - 用于避免重复预加载
  final Set<int> _loadedImages = {};

  // 最大预加载数量限制
  final int maxPreloadCount = 4;

  /// 防抖计时器，50ms内只处理最后一次预加载请求
  Timer? _preloadDebounceTimer;

  /// 图片列表
  List<ChapterImage> get images => context.reader.images;

  /// 预加载图片
  void preloadImages(int startIndex, int endIndex) {
    // 取消之前的预加载计时器
    _preloadDebounceTimer?.cancel();

    // 设置新的防抖计时器，50ms内只处理最后一次预加载请求
    _preloadDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      // 确保方向正确
      final start = startIndex < endIndex ? startIndex : endIndex;
      final end = startIndex < endIndex ? endIndex : startIndex;

      for (int i = start; i <= end; i++) {
        // 检查索引是否有效
        if (i < 0 || i >= images.length) continue;
        // 避免重复加载
        if (_loadedImages.contains(i)) continue;

        final imageUrl = images[i].media.url;
        final imageProvider = CachedNetworkImageProvider(imageUrl);
        precacheImage(imageProvider, context);
        _loadedImages.add(i);
      }
    });
  }

  /// 将图片尺寸信息插入数据库
  void insertImageSize(ImageSize imageSize) {
    ImagesHelper.insert(imageSize);
  }
}
