import 'dart:async' show scheduleMicrotask;
import 'package:flutter/material.dart';
import 'package:haka_comic/utils/request/request_handler.dart';

mixin RequestMixin<T extends StatefulWidget> on State<T> {
  List<RequestHandler> registerHandler();

  bool _scheduled = false;
  bool _dirty = false;

  void _scheduleRebuild() {
    if (_scheduled) return;
    _scheduled = true;

    scheduleMicrotask(() {
      if (mounted && _dirty) {
        setState(() {});
      }
      _dirty = false;
      _scheduled = false;
    });
  }

  R _register<R extends RequestHandler>(R handler) {
    handler.bind(() {
      _dirty = true;
      _scheduleRebuild();
    });
    if (!handler.manual) {
      handler.apply(handler.defaultParams);
    }
    return handler;
  }

  @override
  void initState() {
    super.initState();
    final handlers = registerHandler();
    for (final handler in handlers) {
      _register(handler);
    }
  }
}
