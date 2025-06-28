import 'package:flutter/material.dart';
import 'package:haka_comic/model/reader_provider.dart';

class ReaderInherited extends InheritedWidget {
  /// 漫画ID
  final String cid;

  /// 打开或关闭工具栏
  final VoidCallback openOrCloseToolbar;

  final Size size;

  final ReadMode mode;

  const ReaderInherited({
    super.key,
    required this.cid,
    required this.openOrCloseToolbar,
    required super.child,
    required this.size,
    required this.mode,
  });

  static ReaderInherited of(BuildContext context, {bool listen = true}) {
    return listen
        ? context.dependOnInheritedWidgetOfExactType<ReaderInherited>()!
        : context
                .getElementForInheritedWidgetOfExactType<ReaderInherited>()!
                .widget
            as ReaderInherited;
  }

  @override
  bool updateShouldNotify(covariant ReaderInherited oldWidget) {
    return size != oldWidget.size || mode != oldWidget.mode;
  }
}
