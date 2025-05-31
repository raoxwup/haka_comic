import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void showSnackBar(String message) {
  final currentState = scaffoldMessengerKey.currentState;
  // 检查State是否有效
  if (currentState == null) return;
  // 显示SnackBar
  currentState.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating, // 可选样式调整
      action: SnackBarAction(
        label: '取消',
        onPressed: () {
          currentState.removeCurrentSnackBar();
        },
      ),
    ),
  );
}

String getTextBeforeNewLine(String text) {
  int index = text.indexOf('\n');
  return index != -1 ? text.substring(0, index) : text;
}

String getFormattedTime(String dateString) {
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

String getFormattedDate(String dateString) {
  DateTime dateTime = DateTime.parse(dateString);

  DateTime localDateTime = dateTime.toLocal();

  String year = localDateTime.year.toString();
  String month = _addLeadingZero(localDateTime.month);
  String day = _addLeadingZero(localDateTime.day);

  String formattedDate = "$year-$month-$day";

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
        contentPadding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              spacing: 4,
              children: [
                Text(creator?.name ?? '', style: context.textTheme.titleMedium),
                Text('Lv.${creator?.level ?? 0}'),
                creator?.avatar == null
                    ? Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: Container(
                        width: 110,
                        height: 110,
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assets/images/user.png'),
                      ),
                    )
                    : BaseImage(
                      url: creator?.avatar?.url ?? '',
                      width: 110,
                      height: 110,
                      shape: const CircleBorder(),
                    ),
                Text(creator?.slogan ?? '暂无简介'),
                const SizedBox(height: 10),
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

String formatNumber(int number, {int decimalDigits = 0}) {
  if (number >= 100000) {
    final value = number / 1000;
    String formatted = value.toStringAsFixed(decimalDigits);

    // 移除末尾的零和小数点（如将 123.0k 变为 123k）
    formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');

    return '${formatted}k';
  } else {
    // 手动添加千位分隔符（如 99999 → 99,999）
    return _addThousandsSeparator(number.toString());
  }
}

// 原生实现千位分隔符
String _addThousandsSeparator(String numberStr) {
  final length = numberStr.length;
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    if (i > 0 && (length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(numberStr[i]);
  }
  return buffer.toString();
}

/// 清理名称中的非法字符（路径分隔符和系统保留字符）
String sanitizeFileName(String name, {String replacement = '_'}) {
  final sanitized = name
      .replaceAll(RegExp(r'[/\\]'), replacement)
      .replaceAll(' ', '');
  return sanitized;
}

/// 根据平台返回不同的下载目录
Future<String> getDownloadDirectory() async {
  String path;
  if (isIos || isMacOS) {
    path = (await getApplicationDocumentsDirectory()).path;
  } else {
    final downloadPath = (await getDownloadsDirectory())?.path;
    if (downloadPath == null) {
      if (isAndroid) {
        final externalPath = (await getExternalStorageDirectory())?.path;
        if (externalPath == null) {
          path = (await getApplicationDocumentsDirectory()).path;
        } else {
          path = externalPath;
        }
      } else {
        path = (await getApplicationDocumentsDirectory()).path;
      }
    } else {
      path = downloadPath;
    }
  }
  return path;
}

/// 复制文件
Future<void> copyDirectory(Directory source, Directory destination) async {
  // 创建目标文件夹（包括父目录）
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  // 遍历源目录
  await for (var entity in source.list(recursive: true)) {
    // 计算相对路径
    final relativePath = p.relative(entity.path, from: source.path);
    final newPath = p.join(destination.path, relativePath);

    if (entity is File) {
      // 复制文件
      await File(entity.path).copy(newPath);
    } else if (entity is Directory) {
      // 创建子目录
      await Directory(newPath).create(recursive: true);
    }
  }
}
