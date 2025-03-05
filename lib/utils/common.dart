import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';

void showSnackBar(String message) {
  final currentState = AppConfig.appScaffoldMessengerKey.currentState;
  // 检查State是否有效
  if (currentState == null) return;
  // 显示SnackBar
  currentState.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating, // 可选样式调整
    ),
  );
}

String getTextBeforeNewLine(String text) {
  int index = text.indexOf('\n');
  return index != -1 ? text.substring(0, index) : text;
}
