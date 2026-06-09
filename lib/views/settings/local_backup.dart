import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/utils/backup_utils.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class LocalBackup extends StatefulWidget {
  const LocalBackup({super.key});

  @override
  State<LocalBackup> createState() => _LocalBackupState();
}

class _LocalBackupState extends State<LocalBackup> {
  bool _backingUp = false;
  bool _restoring = false;

  bool get _loading => _backingUp || _restoring;

  Future<void> _backupToLocal() async {
    setState(() => _backingUp = true);

    try {
      String? dirPath;
      try {
        dirPath = await FilePicker.getDirectoryPath();
      } catch (_) {}

      if (dirPath == null || !mounted) {
        setState(() => _backingUp = false);
        return;
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'haka_comic_backup_$timestamp.zip';
      final outputPath = p.join(dirPath, fileName);

      await backupToPath(outputPath);

      if (mounted) {
        Toast.show(message: '备份成功：$fileName');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(message: '备份失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _backingUp = false);
      }
    }
  }

  Future<void> _restoreFromLocal() async {
    setState(() => _restoring = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _restoring = false);
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        setState(() => _restoring = false);
        return;
      }

      final zipFile = File(filePath);
      if (!await zipFile.exists()) {
        Toast.show(message: '文件不存在');
        setState(() => _restoring = false);
        return;
      }

      await restoreFromZip(zipFile);

      if (mounted) {
        context.read<BlockProvider>().syncFromDb();
      }

      if (mounted) {
        Toast.show(message: '恢复成功');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(message: '恢复失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('本地备份')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 备份按钮
              Button.filled(
                onPressed: _loading ? null : _backupToLocal,
                isLoading: _backingUp,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('备份到本地文件'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 恢复按钮
              OutlinedButton(
                onPressed: _loading ? null : _restoreFromLocal,
                child: _restoring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('从本地文件恢复'),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // 说明卡片
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '说明',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '备份：将历史记录、阅读进度、图片缓存、本地收藏、屏蔽项（分类/标签/关键词）等数据打包为 ZIP 文件保存到本地。\n\n'
                        '恢复：从本地 ZIP 备份文件恢复所有数据，当前数据将被覆盖。',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
