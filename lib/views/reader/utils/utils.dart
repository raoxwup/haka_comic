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
