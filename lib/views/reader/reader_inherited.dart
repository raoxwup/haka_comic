import 'package:flutter/material.dart';
import 'package:haka_comic/views/reader/reader.dart';

extension BuildContextExtension on BuildContext {
  /// 获取当前阅读模式
  ReadMode get readMode => ReaderInherited.of(this).mode;

  /// 获取当前漫画ID
  String get cid => ReaderInherited.of(this).cid;

  /// 打开或关闭工具栏
  VoidCallback get openOrCloseToolbar =>
      ReaderInherited.of(this).openOrCloseToolbar;
}

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
