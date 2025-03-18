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

String getFormattedDate(String dateString) {
  // 解析为 DateTime 对象（自动识别 UTC）
  DateTime dateTime = DateTime.parse(dateString);

  // 可选：转换为本地时间（根据需求决定是否调用）
  DateTime localDateTime = dateTime.toLocal();

  // 提取日期时间各部分
  String year = localDateTime.year.toString();
  String month = _addLeadingZero(localDateTime.month);
  String day = _addLeadingZero(localDateTime.day);
  String hour = _addLeadingZero(localDateTime.hour);
  String minute = _addLeadingZero(localDateTime.minute);
  String second = _addLeadingZero(localDateTime.second);

  // 拼接为 YYYY-MM-DD HH:mm:ss 格式
  String formattedDate = "$year-$month-$day $hour:$minute:$second";

  return formattedDate;
}

String _addLeadingZero(int number) {
  return number.toString().padLeft(2, '0');
}
