import 'package:flutter/widgets.dart';
import 'package:haka_comic/utils/extension.dart';

mixin AutoRegisterHandlerMixin<T extends StatefulWidget> on State<T> {
  /// 注册请求处理器
  late final List<AsyncRequestHandler> _handlers;

  /// 注册请求处理器方法
  List<AsyncRequestHandler> registerHandler();

  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _handlers = registerHandler();
    for (var handler in _handlers) {
      handler.addListener(update);
    }
  }

  @override
  void dispose() {
    for (var handler in _handlers) {
      handler.dispose();
    }
    super.dispose();
  }
}
