import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:legalize/legalize.dart';
import 'package:path/path.dart' as p;

extension WaitFuture<T> on Future<T> {
  Future<void> wait() async {
    try {
      await this;
    } catch (e) {
      Log.error('unexpected error', e);
    }
  }
}

extension BuildContextExt on BuildContext {
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get left => padding.left;
  double get right => padding.right;
  double get top => padding.top;
  double get bottom => padding.bottom;

  Size get size => MediaQuery.sizeOf(this);
  double get width => size.width;
  double get height => size.height;

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}

extension StringExt on String {
  String substringSafe(int start, [int? end]) {
    if (start < 0 || (end != null && end < start)) {
      return '';
    }
    if (end == null || end > length) {
      end = length;
    }
    return substring(start, end);
  }
}

extension Legalized on String {
  String get legalized {
    final str = legalizeFilename(this, os: Platform.operatingSystem);
    const max = 255;
    if (str.length <= max) return str;
    final ext = p.extension(str);

    if (ext.isNotEmpty && str.length > max) {
      final name = str.substring(0, max - ext.length);
      return '$name$ext';
    }

    return str.substring(0, max);
  }
}
