import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/ui_image.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void showSnackBar(String message) {
  final currentState = scaffoldMessengerKey.currentState;
  // 检查State是否有效
  if (currentState == null) return;
  // 显示SnackBar
  currentState.showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

String getTextBeforeNewLine(String text) {
  int index = text.indexOf('\n');
  return index != -1 ? text.substring(0, index) : text;
}

String getFormattedTime(String dateString) {
  return Jiffy.parse(dateString).format(pattern: 'yyyy-MM-dd HH:mm:ss');
}

String getFormattedDate(String dateString) {
  return Jiffy.parse(dateString).format(pattern: 'yyyy-MM-dd');
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
                    : UiImage(
                        url: creator?.avatar!.url ?? '',
                        width: 110,
                        height: 110,
                        shape: .circle,
                      ),
                Text(creator?.slogan ?? '暂无简介'),
                const SizedBox(height: 10),
                Row(
                  spacing: 2,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (creator?.role == 'knight')
                      TextButton(
                        onPressed: () =>
                            context.push('/comics?ca=${creator?.id}'),
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

/// 根据平台返回不同的下载目录
Future<String> getDownloadDirectory() async {
  if (isIos || isMacOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }

  final downloadPath = (await getDownloadsDirectory())?.path;
  if (downloadPath != null) return downloadPath;

  if (isAndroid) {
    final externalPath = (await getExternalStorageDirectory())?.path;
    if (externalPath != null) return externalPath;
  }

  return (await getApplicationDocumentsDirectory()).path;
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

/// 分割列表
List<List<E>> splitList<E>(List<E> list, int n) {
  final result = <List<E>>[];
  for (var i = 0; i < list.length; i += n) {
    // 计算当前组的结束位置（不超过列表长度）
    final end = (i + n) < list.length ? i + n : list.length;
    // 截取子列表并添加到结果
    result.add(list.sublist(i, end));
  }
  return result;
}

Future<void> showHalfScreenDialog(BuildContext context, Widget child) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 400,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => child,
                  settings: settings,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
