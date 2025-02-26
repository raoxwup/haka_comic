import 'package:flutter/foundation.dart';

extension FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) predicate) {
    for (final element in this) {
      if (predicate(element)) return element;
    }
    return null;
  }
}

enum LogLevel { error, warning, info }

class LogItem {
  final LogLevel level;
  final String title;
  final String content;
  final DateTime time = DateTime.now();

  LogItem(this.level, this.title, this.content);

  @override
  String toString() => "${level.name} $title $time \n$content\n\n";
}

class Log {
  static final List<LogItem> _items = [];

  static List<LogItem> get items => _items;

  static const int maxItemLength = 3000;

  static const int maxItemsNumber = 500;

  static void printWarning(String text) {
    debugPrint('\x1B[33m$text\x1B[0m');
  }

  static void printError(String text) {
    debugPrint('\x1B[31m$text\x1B[0m');
  }

  static void add(LogLevel level, String title, String content) {
    if (content.length > maxItemLength) {
      content = "${content.substring(0, maxItemLength)}...";
    }

    switch (level) {
      case LogLevel.error:
        printError(content);
        break;
      case LogLevel.warning:
        printWarning(content);
        break;
      case LogLevel.info:
        if (kDebugMode) {
          debugPrint(content);
        }
    }

    var item = LogItem(level, title, content);

    if (item == _items.lastOrNull) {
      return;
    }

    _items.add(item);

    if (_items.length > maxItemsNumber) {
      var res = _items.remove(
        _items.firstWhereOrNull((element) => element.level == LogLevel.info),
      );
      if (!res) {
        _items.removeAt(0);
      }
    }
  }

  static info(String title, String content) {
    add(LogLevel.info, title, content);
  }

  static warning(String title, String content) {
    add(LogLevel.warning, title, content);
  }

  static error(String title, Object content, [Object? stackTrace]) {
    var info = content.toString();
    if (stackTrace != null) {
      info += "\n${stackTrace.toString()}";
    }
    add(LogLevel.error, title, info);
  }

  static void clear() => _items.clear();

  @override
  String toString() {
    var res = "Logs\n\n";
    for (var log in _items) {
      res += log.toString();
    }
    return res;
  }
}
