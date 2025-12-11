enum ReadMode {
  vertical('连续从上到下'),

  leftToRight('单页从左到右'),

  rightToLeft('单页从右到左'),

  doubleLeftToRight('双页从左到右'),

  doubleRightToLeft('双页从右到左');

  final String displayName;

  const ReadMode(this.displayName);

  static ReadMode fromName(String? name) {
    return ReadMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => vertical,
    );
  }

  bool get isVertical => this == vertical;

  bool get isDoublePage =>
      this == doubleLeftToRight || this == doubleRightToLeft;

  bool get isReverse =>
      this == ReadMode.rightToLeft || this == ReadMode.doubleRightToLeft;
}
