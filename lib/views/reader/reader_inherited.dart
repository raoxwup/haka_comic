import 'package:flutter/material.dart';

class ReaderInherited extends InheritedWidget {
  /// 漫画ID
  final String cid;

  /// 打开或关闭工具栏
  final VoidCallback openOrCloseToolbar;

  const ReaderInherited({
    super.key,
    required this.cid,
    required this.openOrCloseToolbar,
    required super.child,
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
    return cid != oldWidget.cid;
  }
}
