import 'dart:async' show scheduleMicrotask;
import 'package:flutter/material.dart';
import 'package:haka_comic/utils/request/request_handler.dart';

abstract class RequestProvider extends ChangeNotifier {
  bool _scheduled = false;
  bool _dirty = false;
  bool _disposed = false;

  void _scheduleNotify() {
    if (_scheduled) return;

    _scheduled = true;

    scheduleMicrotask(() {
      if (_disposed) return;

      if (_dirty) {
        notifyListeners();
      }

      _dirty = false;
      _scheduled = false;
    });
  }

  R register<R extends RequestHandler>(R handler) {
    handler.bind(() {
      _dirty = true;
      _scheduleNotify();
    });

    if (!handler.manual) {
      handler.apply(handler.defaultParams);
    }

    return handler;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
