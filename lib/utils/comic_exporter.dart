import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/rust/api/compress.dart';
import 'package:haka_comic/rust/api/simple.dart';
import 'package:haka_comic/utils/android_download_saver.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/loader.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/save_to_folder_ios.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ExportFileType { pdf, zip }

typedef ComicExportItem = ({String fileStem, String sourceFolderPath});

const String exportFileTempDir = 'export_temp';

class ComicExporter {
  ComicExporter._();

  /// 统一导出入口。导出完成（无论成功或失败）后都会调用 [onComplete]。
  static Future<void> export({
    required BuildContext context,
    required List<ComicExportItem> items,
    required ExportFileType type,
    VoidCallback? onComplete,
  }) async {
    try {
      if (isAndroid) {
        await _exportForAndroid(context: context, items: items, type: type);
      } else if (isDesktop) {
        await _exportForDesktop(context: context, items: items, type: type);
      } else {
        await _exportForIos(context: context, items: items, type: type);
      }
    } catch (e, st) {
      Log.e('Export comics failed', error: e, stackTrace: st);
      Toast.show(message: '导出失败');
    } finally {
      if (context.mounted) {
        Loader.hide(context);
      }
      onComplete?.call();
    }
  }

  static Future<void> _exportForDesktop({
    required BuildContext context,
    required List<ComicExportItem> items,
    required ExportFileType type,
  }) async {
    final selectedDirectoryPath = await FilePicker.getDirectoryPath();

    if (selectedDirectoryPath == null) {
      Toast.show(message: '未选择导出目录');
      return;
    }

    if (context.mounted) {
      Loader.show(context);
    }

    for (final item in items) {
      final destPath = p.join(
        selectedDirectoryPath,
        '${item.fileStem}.${type.name}',
      );
      await _buildFile(
        sourceFolderPath: item.sourceFolderPath,
        outputPath: destPath,
        type: type,
      );
    }

    Toast.show(message: '导出成功');
  }

  static Future<void> _exportForIos({
    required BuildContext context,
    required List<ComicExportItem> items,
    required ExportFileType type,
  }) async {
    if (context.mounted) {
      Loader.show(context);
    }

    final path = await _buildIosExportPath(items: items, type: type);
    final success = await SaveToFolderIos.copy(path);
    Toast.show(message: success ? '导出成功' : '导出失败');
  }

  static Future<void> _exportForAndroid({
    required BuildContext context,
    required List<ComicExportItem> items,
    required ExportFileType type,
  }) async {
    if (!await _ensureAndroidPermission(context)) {
      return;
    }

    if (context.mounted) {
      Loader.show(context);
    }

    final cacheDir = await getApplicationCacheDirectory();

    for (final item in items) {
      final fileName = '${item.fileStem}.${type.name}';
      final destPath = p.join(cacheDir.path, exportFileTempDir, fileName);

      await _buildFile(
        sourceFolderPath: item.sourceFolderPath,
        outputPath: destPath,
        type: type,
      );

      await AndroidDownloadSaver.saveToDownloads(
        filePath: destPath,
        fileName: fileName,
      );
    }

    Toast.show(message: '导出成功');
  }

  static Future<void> _buildFile({
    required String sourceFolderPath,
    required String outputPath,
    required ExportFileType type,
  }) async {
    switch (type) {
      case ExportFileType.pdf:
        await exportPdf(
          sourceFolderPath: sourceFolderPath,
          outputPdfPath: outputPath,
        );
        break;
      case ExportFileType.zip:
        await compress(
          sourceFolderPath: sourceFolderPath,
          outputZipPath: outputPath,
          compressionMethod: CompressionMethod.stored,
        );
        break;
    }
  }

  static Future<String> _buildIosExportPath({
    required List<ComicExportItem> items,
    required ExportFileType type,
  }) {
    return switch (type) {
      ExportFileType.pdf => _buildIosPdfExportPath(items),
      ExportFileType.zip => _buildIosZipExportPath(items),
    };
  }

  static Future<String> _buildIosZipExportPath(
    List<ComicExportItem> items,
  ) async {
    final tempDir = await _createCleanTempDirectory();
    final name = items.length == 1
        ? '${items.first.fileStem}.zip'
        : 'comics.zip';
    final zipPath = p.join(tempDir.path, name);

    final zipper = await createZipper(
      zipPath: zipPath,
      compressionMethod: CompressionMethod.stored,
    );

    for (final item in items) {
      await zipper.addDirectory(dirPath: item.sourceFolderPath);
    }

    await zipper.close();
    return zipPath;
  }

  static Future<String> _buildIosPdfExportPath(
    List<ComicExportItem> items,
  ) async {
    final tempDir = await _createCleanTempDirectory();

    if (items.length == 1) {
      final item = items.first;
      final pdfPath = p.join(tempDir.path, '${item.fileStem}.pdf');
      await _buildFile(
        sourceFolderPath: item.sourceFolderPath,
        outputPath: pdfPath,
        type: ExportFileType.pdf,
      );
      return pdfPath;
    }

    final zipPath = p.join(tempDir.path, 'comics.zip');
    final zipper = await createZipper(
      zipPath: zipPath,
      compressionMethod: CompressionMethod.stored,
    );

    for (final item in items) {
      final pdfPath = p.join(tempDir.path, '${item.fileStem}.pdf');
      await _buildFile(
        sourceFolderPath: item.sourceFolderPath,
        outputPath: pdfPath,
        type: ExportFileType.pdf,
      );
      await zipper.addFile(filePath: pdfPath);
    }

    await zipper.close();
    return zipPath;
  }

  static Future<Directory> _createCleanTempDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final tempDir = Directory(p.join(cacheDir.path, exportFileTempDir));

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }

    await tempDir.create(recursive: true);
    return tempDir;
  }

  static Future<bool> _ensureAndroidPermission(BuildContext context) async {
    final version = await AndroidDownloadSaver.getAndroidVersion();

    if (version > 28) {
      return true;
    }

    final status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) {
        return false;
      }
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('缺少权限'),
            content: const Text('请在设置中开启存储权限后重试'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  context.pop();
                },
                child: const Text('打开设置'),
              ),
            ],
          );
        },
      );
      return false;
    }

    Toast.show(message: '没有必要的存储权限');
    return false;
  }
}
