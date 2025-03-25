import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/widgets/base_image.dart';

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

void showCreator(BuildContext context, Creator? creator) {
  showDialog(
    context: context,
    builder: (context) {
      return SimpleDialog(
        contentPadding: EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              spacing: 4,
              children: [
                Text(
                  creator?.name ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Lv.${creator?.level ?? 0}'),
                creator?.avatar == null
                    ? Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 0,
                      shape: CircleBorder(),
                      child: Container(
                        width: 110,
                        height: 110,
                        padding: EdgeInsets.all(10),
                        child: Image.asset('assets/images/user.png'),
                      ),
                    )
                    : BaseImage(
                      url: creator?.avatar?.url ?? '',
                      width: 110,
                      height: 110,
                      shape: CircleBorder(),
                    ),
                Text(creator?.slogan ?? '暂无简介'),
                SizedBox(height: 10),
                Row(
                  spacing: 2,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (creator?.role == 'knight')
                      TextButton(
                        onPressed:
                            () => context.push('/comics?ca=${creator?.id}'),
                        child: const Text("Ta的上传"),
                      ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

bool isIos = Platform.isIOS;
bool isAndroid = Platform.isAndroid;
bool isMacOS = Platform.isMacOS;
bool isWindows = Platform.isWindows;
bool isLinux = Platform.isLinux;

bool get isDesktop => isMacOS || isWindows || isLinux;
