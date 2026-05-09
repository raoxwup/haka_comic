import 'dart:async';
import 'dart:io';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';

/// 图片预加载控制器
class ImagePreloadController<T> {
  ImagePreloadController({
    required this.context,
    required this.items,
    required this.urlResolver,
    required this.type,
    this.maxPreloadCount = 4,
    this.keepWindow = 10,
    this.debounceDuration = const Duration(milliseconds: 50),
    this.cacheWidth,
  });

  final BuildContext context;
  List<T> items;
  final String Function(T item) urlResolver;
  final ReaderType type;

  /// 单次最大预加载数量
  int maxPreloadCount;

  /// 预加载索引保留窗口（前后）
  final int keepWindow;

  /// 防抖时长
  final Duration debounceDuration;

  /// 解码宽度（物理像素）。与显示端保持一致可共享 ImageCache 条目。
  /// 为 null 时不做尺寸限制（即使用原始分辨率解码）。
  int? cacheWidth;

  Timer? _debounceTimer;

  int _generation = 0;

  /// 已预加载索引集合
  final Set<(int, int)> _preloaded = {};

  /// 最近一次锚点索引，用于判断滚动方向
  int _lastAnchorIndex = 0;

  /// 对外：在锚点变化时调用（PageView page / ListView firstVisible）
  void onAnchorChanged(List<int> indexes) {
    final first = indexes.first;
    final last = indexes.last;
    final isBackward = first < _lastAnchorIndex;

    if (isBackward) {
      _schedulePreload(
        start: first - 1,
        end: first - maxPreloadCount,
        anchor: first,
      );
    } else {
      _schedulePreload(
        start: last + 1,
        end: last + maxPreloadCount,
        anchor: last,
      );
    }

    _lastAnchorIndex = first;
  }

  /// 主调度逻辑（带 debounce）
  void _schedulePreload({
    required int start,
    required int end,
    required int anchor,
  }) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(debounceDuration, () {
      if (!context.mounted) return;

      _trimPreloaded(anchor);

      final from = start < end ? start : end;
      final to = start < end ? end : start;

      int count = 0;
      for (int i = from; i <= to; i++) {
        if (count >= maxPreloadCount) break;
        if (i < 0 || i >= items.length) continue;

        final key = (_generation, i);

        if (_preloaded.contains(key)) continue;

        _preloaded.add(key);
        count++;

        final url = urlResolver(items[i]);
        final ImageProvider base = type == ReaderType.network
            ? CachedNetworkImageProvider(url)
            : FileImage(File(url));
        // 用与显示端一致的 ResizeImage 包裹，保证预加载进入的是同一个缓存键，
        // 否则真正显示时会因 key 不同而重新解码一次，相当于白预加载。
        final ImageProvider provider = cacheWidth != null
            ? ResizeImage.resizeIfNeeded(cacheWidth, null, base)
            : base;
        precacheImage(provider, context, onError: (_, _) {});
      }
    });
  }

  void _trimPreloaded(int anchor) {
    _preloaded.removeWhere((key) {
      final (gen, index) = key;
      if (gen != _generation) return true;
      return (index - anchor).abs() > keepWindow;
    });
  }

  void replaceItems(List<T> items) {
    _debounceTimer?.cancel();
    this.items = items;
    _generation++;
    _lastAnchorIndex = 0;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _preloaded.clear();
  }
}
