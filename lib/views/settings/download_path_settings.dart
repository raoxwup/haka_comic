import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';

class DownloadPathSettings extends StatefulWidget {
  const DownloadPathSettings({super.key});

  @override
  State<DownloadPathSettings> createState() => _DownloadPathSettingsState();
}

class _DownloadPathSettingsState extends State<DownloadPathSettings> {
  final appConf = AppConf();

  String get _currentPath => appConf.downloadPath;

  Future<void> _pickDirectory() async {
    String? dirPath;
    try {
      dirPath = await FilePicker.getDirectoryPath();
    } catch (_) {}

    if (dirPath == null || !mounted) return;

    appConf.downloadPath = dirPath;
    setState(() {});

    if (mounted) {
      Toast.show(message: '下载路径已更新');
    }
  }

  void _resetToDefault() {
    appConf.downloadPath = '';
    setState(() {});

    if (mounted) {
      Toast.show(message: '已恢复默认下载路径');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final hasCustom = _currentPath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('下载路径')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 当前路径卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '当前下载路径',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (hasCustom)
                            Text(
                              '自定义',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasCustom
                            ? _currentPath
                            : '使用系统默认路径（根据平台自动选择）',
                        style: textTheme.bodyMedium?.copyWith(
                          color: hasCustom
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 选择目录按钮
              Button.filled(
                onPressed: _pickDirectory,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 20),
                    SizedBox(width: 8),
                    Text('选择下载目录'),
                  ],
                ),
              ),

              if (hasCustom) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetToDefault,
                  icon: const Icon(Icons.restore, size: 20),
                  label: const Text('恢复默认路径'),
                ),
              ],

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
                        '设置漫画下载的保存目录。修改后新下载的漫画将保存到新路径，已有下载文件不受影响。\n\n'
                        '恢复默认后将使用系统推荐的下载目录。',
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
