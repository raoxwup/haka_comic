import 'dart:async';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';

/// 图片预加载控制器
class ImagePreloadController<T> {
  ImagePreloadController({
    required this.context,
    required this.items,
    required this.urlResolver,
    this.maxPreloadCount = 4,
    this.keepWindow = 10,
    this.debounceDuration = const Duration(milliseconds: 50),
  });

  final BuildContext context;
  List<T> items;
  final String Function(T item) urlResolver;

  /// 单次最大预加载数量
  final int maxPreloadCount;

  /// 预加载索引保留窗口（前后）
  final int keepWindow;

  /// 防抖时长
  final Duration debounceDuration;

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
        precacheImage(ExtendedNetworkImageProvider(url, cache: true), context);
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
