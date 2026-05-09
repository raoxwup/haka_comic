import 'dart:math' as math show log;
import 'dart:ui';

/// 单页页码转换为正确的多页页码
int toCorrectMultiPageNo(int pageNo, int pageSize) {
  return pageNo ~/ pageSize;
}

/// 多页页码转换为正确的单页页码
int toCorrectSinglePageNo(int pageNo, int pageSize) {
  return pageNo * pageSize;
}

/// [pageSize]页页码转换为[anotherPageSize]页页码
int toAnotherMultiPageNo(int pageNo, int pageSize, int anotherPageSize) {
  return (pageNo * pageSize) ~/ anotherPageSize;
}

/// 获取屏幕高度
double get screenHeight {
  // 获取主视图
  final view = PlatformDispatcher.instance.views.first;

  // 物理尺寸 (以物理像素为单位)
  final physicalSize = view.physicalSize;
  final physicalHeight = physicalSize.height;

  // 设备像素比
  final devicePixelRatio = view.devicePixelRatio;

  // 逻辑高度 (以逻辑像素为单位)
  final logicalHeight = physicalHeight / devicePixelRatio;

  return logicalHeight;
}

// 计算下载进度
double computeProgress(int bytes) {
  const double maxProgress = 0.95;
  const double scale = 35 * 1024;

  final p = math.log(bytes / scale + 1);
  final normalized = p / (p + 1);

  return (normalized * maxProgress).clamp(0.0, maxProgress);
}

/// 计算图片解码的 cacheWidth（物理像素）
///
/// 按 [layoutWidth] × [devicePixelRatio] × [zoomHeadroom] 计算所需的解码宽度，
/// 再夹到 [minWidth]~[maxWidth] 区间，避免过小模糊或过大占内存。
///
/// - [layoutWidth]: 图片在布局中实际占用的逻辑宽度（如双页模式为半屏宽）
/// - [devicePixelRatio]: 设备像素比，通过 MediaQuery.devicePixelRatioOf(context) 获取
/// - [zoomHeadroom]: 缩放冗余倍数。默认 2.0 可以在 ~2x 放大时保持原图级清晰度，
///   4x 极限放大时略柔化。如需更清晰可提高到 2.5 或 3.0，但内存占用会成平方增长。
/// - [minWidth]: 下限，小屏上也保证基本细节，默认 1080。
/// - [maxWidth]: 上限，防止大屏设备解码出 8K 级位图，默认 3840。
int computeImageCacheWidth({
  required double layoutWidth,
  required double devicePixelRatio,
  double zoomHeadroom = 2.0,
  int minWidth = 1080,
  int maxWidth = 3840,
}) {
  if (layoutWidth <= 0 || devicePixelRatio <= 0 || !layoutWidth.isFinite) {
    return maxWidth;
  }
  final raw = (layoutWidth * devicePixelRatio * zoomHeadroom).round();
  return raw.clamp(minWidth, maxWidth);
}
