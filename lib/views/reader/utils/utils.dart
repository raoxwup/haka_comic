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
