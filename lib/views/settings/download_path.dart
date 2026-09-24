import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/macos_security_scoped_bookmark.dart';
import 'package:haka_comic/utils/native_folder_picker.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/views/download/download_storage.dart';
import 'package:haka_comic/views/download/download_storage_migration.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path/path.dart' as p;

class DownloadPathSetting extends StatefulWidget {
  const DownloadPathSetting({super.key});

  @override
  State<DownloadPathSetting> createState() => _DownloadPathSettingState();
}

class _DownloadPathSettingState extends State<DownloadPathSetting> {
  bool _isChanging = false;
  late String _displayValue = _configuredDisplayValue();

  String _configuredDisplayValue() {
    if (isAndroid) {
      return AppConf().androidDownloadTreeName ?? '默认位置';
    }
    return AppConf().desktopDownloadDirectory ?? '默认位置';
  }

  Future<void> _showActions() async {
    if (_isChanging) return;

    final hasCustomLocation = isAndroid
        ? AppConf().androidDownloadTreeUri != null
        : AppConf().desktopDownloadDirectory != null;
    final action = await showModalBottomSheet<_DownloadPathAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('选择文件夹'),
              onTap: () => context.pop(_DownloadPathAction.choose),
            ),
            if (hasCustomLocation)
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('恢复默认位置'),
                onTap: () => context.pop(_DownloadPathAction.reset),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == _DownloadPathAction.choose) {
      await _chooseLocation();
    } else if (action == _DownloadPathAction.reset) {
      await _resetLocation();
    }
  }

  Future<void> _chooseLocation() async {
    final previousDesktopPath = AppConf().desktopDownloadDirectory;
    final previousDesktopBookmark = AppConf().desktopDownloadBookmark;
    final previousAndroidUri = AppConf().androidDownloadTreeUri;
    final previousAndroidName = AppConf().androidDownloadTreeName;
    DownloadStorage? destination;
    String? desktopPath;
    String? desktopBookmark;
    PickedWritableFolder? androidFolder;

    if (isAndroid) {
      androidFolder = await NativeFolderPicker.pickWritableDirectory();
      if (androidFolder == null) return;
      destination = DownloadStorage.androidSaf(
        treeUri: androidFolder.uri,
        displayName: androidFolder.name,
      );
    } else {
      desktopPath = await FilePicker.getDirectoryPath(dialogTitle: '选择下载文件夹');
      if (desktopPath == null) return;
      if (isMacOS) {
        try {
          desktopBookmark = await MacOsSecurityScopedBookmark.create(
            desktopPath,
          );
        } catch (error, stackTrace) {
          Log.e(
            'create macOS download directory bookmark failed',
            error: error,
            stackTrace: stackTrace,
          );
          Toast.show(message: '无法保存所选文件夹的访问权限');
          return;
        }
      }
      destination = DownloadStorage.local(desktopPath);
    }

    if (await _isReauthorizingCurrentLocation(
      previousDesktopPath: previousDesktopPath,
      desktopPath: desktopPath,
      previousAndroidUri: previousAndroidUri,
      androidFolder: androidFolder,
    )) {
      await _reauthorizeCurrentLocation(
        persistLocation: () async {
          if (isAndroid) {
            await AppConf().setAndroidDownloadTree(
              uri: androidFolder!.uri,
              name: androidFolder.name,
            );
          } else {
            await AppConf().setDesktopDownloadDirectory(
              desktopPath,
              bookmark: desktopBookmark,
            );
          }
        },
        restoreLocation: () async {
          if (isAndroid) {
            await AppConf().setAndroidDownloadTree(
              uri: previousAndroidUri,
              name: previousAndroidName,
            );
          } else {
            await AppConf().setDesktopDownloadDirectory(
              previousDesktopPath,
              bookmark: previousDesktopBookmark,
            );
          }
        },
      );
      return;
    }

    final source = await DownloadStorage.currentFromConfig();
    final sourceAvailable = await _isStorageAvailable(source);
    if (await _isSameOrNestedLocation(
      source,
      destination,
      failClosedForUnknownSaf: sourceAvailable,
    )) {
      Toast.show(message: '请选择与当前下载目录不同、且互不包含的文件夹');
      return;
    }

    await _migrate(
      source: source,
      destination: destination,
      persistDestination: () async {
        if (isAndroid) {
          await AppConf().setAndroidDownloadTree(
            uri: androidFolder!.uri,
            name: androidFolder.name,
          );
        } else {
          await AppConf().setDesktopDownloadDirectory(
            desktopPath,
            bookmark: desktopBookmark,
          );
        }
      },
      restoreSource: () async {
        if (isAndroid) {
          await AppConf().setAndroidDownloadTree(
            uri: previousAndroidUri,
            name: previousAndroidName,
          );
        } else {
          await AppConf().setDesktopDownloadDirectory(
            previousDesktopPath,
            bookmark: previousDesktopBookmark,
          );
        }
      },
    );
  }

  Future<bool> _isReauthorizingCurrentLocation({
    required String? previousDesktopPath,
    required String? desktopPath,
    required String? previousAndroidUri,
    required PickedWritableFolder? androidFolder,
  }) async {
    if (isAndroid) {
      return previousAndroidUri != null &&
          previousAndroidUri == androidFolder?.uri;
    }
    if (!isMacOS || previousDesktopPath == null || desktopPath == null) {
      return false;
    }
    return p.equals(
      await _resolvedLocalPath(previousDesktopPath),
      await _resolvedLocalPath(desktopPath),
    );
  }

  Future<void> _reauthorizeCurrentLocation({
    required Future<void> Function() persistLocation,
    required Future<void> Function() restoreLocation,
  }) async {
    setState(() => _isChanging = true);
    var persistAttempted = false;
    var persistSucceeded = false;
    try {
      await BackgroundDownloader.stopForStorageChange();
      persistAttempted = true;
      await persistLocation();
      persistSucceeded = true;
      await BackgroundDownloader.restartAfterStorageChange();
      BackgroundDownloader.getTasks();
      if (mounted) {
        setState(() => _displayValue = _configuredDisplayValue());
      }
      Toast.show(message: '下载位置访问权限已恢复');
    } catch (error, stackTrace) {
      Log.e(
        'reauthorize download storage failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (persistAttempted && !persistSucceeded) {
        try {
          await restoreLocation();
        } catch (restoreError, restoreStackTrace) {
          Log.e(
            'restore download location after reauthorization failure',
            error: restoreError,
            stackTrace: restoreStackTrace,
          );
        }
      }
      try {
        await BackgroundDownloader.restartAfterStorageChange();
        BackgroundDownloader.getTasks();
      } catch (restartError, restartStackTrace) {
        Log.e(
          'restart downloader after reauthorization failure',
          error: restartError,
          stackTrace: restartStackTrace,
        );
      }
      if (mounted) {
        setState(() => _displayValue = _configuredDisplayValue());
      }
      Toast.show(message: '无法恢复下载位置访问权限');
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  Future<void> _resetLocation() async {
    final previousDesktopPath = AppConf().desktopDownloadDirectory;
    final previousDesktopBookmark = AppConf().desktopDownloadBookmark;
    final previousAndroidUri = AppConf().androidDownloadTreeUri;
    final previousAndroidName = AppConf().androidDownloadTreeName;
    final source = await DownloadStorage.currentFromConfig();
    final destination = DownloadStorage.local(
      await getDefaultDownloadDirectory(),
      displayName: '默认位置',
    );
    final sourceAvailable = await _isStorageAvailable(source);
    if (await _isSameOrNestedLocation(
      source,
      destination,
      failClosedForUnknownSaf: sourceAvailable,
    )) {
      return;
    }

    await _migrate(
      source: source,
      destination: destination,
      persistDestination: () async {
        if (isAndroid) {
          await AppConf().setAndroidDownloadTree(uri: null, name: null);
        } else {
          await AppConf().setDesktopDownloadDirectory(null);
        }
      },
      restoreSource: () async {
        if (isAndroid) {
          await AppConf().setAndroidDownloadTree(
            uri: previousAndroidUri,
            name: previousAndroidName,
          );
        } else {
          await AppConf().setDesktopDownloadDirectory(
            previousDesktopPath,
            bookmark: previousDesktopBookmark,
          );
        }
      },
    );
  }

  Future<bool> _isSameOrNestedLocation(
    DownloadStorage source,
    DownloadStorage destination, {
    required bool failClosedForUnknownSaf,
  }) async {
    final sourceTreeUri = source.androidTreeUri;
    final destinationTreeUri = destination.androidTreeUri;
    if (sourceTreeUri != null && sourceTreeUri == destinationTreeUri) {
      return true;
    }

    final sourcePathValue =
        source.localRootPath ??
        (sourceTreeUri == null
            ? null
            : await NativeFolderPicker.resolveTreePath(sourceTreeUri));
    final destinationPathValue =
        destination.localRootPath ??
        (destinationTreeUri == null
            ? null
            : await NativeFolderPicker.resolveTreePath(destinationTreeUri));
    if (sourcePathValue != null && destinationPathValue != null) {
      final sourcePath = await _resolvedLocalPath(sourcePathValue);
      final destinationPath = await _resolvedLocalPath(destinationPathValue);
      return p.equals(sourcePath, destinationPath) ||
          p.isWithin(sourcePath, destinationPath) ||
          p.isWithin(destinationPath, sourcePath);
    }

    if (sourceTreeUri != null && destinationTreeUri != null) {
      if (await NativeFolderPicker.areTreesNested(
        firstTreeUri: sourceTreeUri,
        secondTreeUri: destinationTreeUri,
      )) {
        return true;
      }

      // DocumentProvider 的 isChildDocument 是可选能力。同一 provider 无法解析
      // 实际路径且返回 false 时，无法证明两个目录互不包含，必须保守拒绝。
      return failClosedForUnknownSaf &&
          Uri.parse(sourceTreeUri).authority ==
              Uri.parse(destinationTreeUri).authority;
    }

    return false;
  }

  Future<bool> _isStorageAvailable(DownloadStorage storage) async {
    try {
      await storage.ensureReady();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolvedLocalPath(String path) async {
    try {
      return p.canonicalize(await Directory(path).resolveSymbolicLinks());
    } on FileSystemException {
      return p.canonicalize(path);
    }
  }

  Future<void> _migrate({
    required DownloadStorage source,
    required DownloadStorage destination,
    required Future<void> Function() persistDestination,
    required Future<void> Function() restoreSource,
  }) async {
    try {
      await DownloadStorageMigrator.recoverPendingMigration();
      await destination.ensureReady();
    } catch (error, stackTrace) {
      Log.e(
        'prepare download migration destination failed',
        error: error,
        stackTrace: stackTrace,
      );
      Toast.show(message: '新下载位置不可用，或上次迁移的残留无法清理');
      return;
    }

    var sourceAvailable = true;
    try {
      await source.ensureReady();
    } catch (error, stackTrace) {
      sourceAvailable = false;
      Log.w(
        'current download storage is unavailable',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sourceAvailable ? '更改下载位置' : '原下载位置不可用'),
        content: Text(
          sourceAvailable
              ? '现有下载内容会迁移到新位置。迁移完成前请保持应用运行。'
              : '无法访问原下载位置，因此不能迁移旧文件。继续后会切换到新位置；现有记录会保留，但对应文件可能需要重新下载或导入。',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(sourceAvailable ? '开始迁移' : '仍然切换'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isChanging = true);
    final progress = ValueNotifier<DownloadMigrationProgress>(
      const DownloadMigrationProgress(
        stage: DownloadMigrationStage.preparing,
        copiedBytes: 0,
        totalBytes: 0,
      ),
    );
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _MigrationProgressDialog(progress: progress),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    var switched = false;
    var configurationChangeAttempted = false;
    var rollbackCompleted = true;
    DownloadStorageMigrationResult? migrationResult;
    try {
      await BackgroundDownloader.stopForStorageChange();
      final migrator = DownloadStorageMigrator();
      if (sourceAvailable) {
        migrationResult = await migrator.copyAndVerify(
          source: source,
          destination: destination,
          onProgress: (value) => progress.value = value,
        );
      }
      configurationChangeAttempted = true;
      await persistDestination();
      await BackgroundDownloader.restartAfterStorageChange();
      switched = true;
      BackgroundDownloader.getTasks();
      if (migrationResult != null) {
        try {
          await DownloadStorageMigrator.markPendingMigrationCommitted();
        } catch (error, stackTrace) {
          Log.w(
            'clear committed download migration journal failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
        await migrator.cleanupSource(
          source: source,
          result: migrationResult,
          onProgress: (value) => progress.value = value,
        );
      }

      if (mounted) {
        setState(() => _displayValue = _configuredDisplayValue());
      }
      Toast.show(message: sourceAvailable ? '下载位置已更改' : '下载位置已切换，旧文件未迁移');
    } catch (error, stackTrace) {
      Log.e(
        'download storage migration failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!switched) {
        if (configurationChangeAttempted) {
          try {
            await restoreSource();
          } catch (restoreError, restoreStackTrace) {
            rollbackCompleted = false;
            Log.e(
              'restore download storage configuration failed',
              error: restoreError,
              stackTrace: restoreStackTrace,
            );
          }
        }
        if (migrationResult != null && rollbackCompleted) {
          final cleaned = await DownloadStorageMigrator().cleanupDestination(
            destination: destination,
            result: migrationResult,
          );
          if (!cleaned) rollbackCompleted = false;
        }
        try {
          await BackgroundDownloader.restartAfterStorageChange();
          BackgroundDownloader.getTasks();
        } catch (restartError, restartStackTrace) {
          Log.e(
            'restart downloader after migration failure',
            error: restartError,
            stackTrace: restartStackTrace,
          );
        }
      }
      Toast.show(
        message: rollbackCompleted
            ? (sourceAvailable ? '迁移失败，仍使用原下载位置' : '切换失败，仍使用原下载位置')
            : migrationResult == null
            ? '切换失败，请重新选择下载位置'
            : '迁移失败，请重新选择下载位置；新位置的文件已保留',
      );
    } finally {
      if (mounted) {
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        if (rootNavigator.canPop()) rootNavigator.pop();
        setState(() => _isChanging = false);
      }
      await Future<void>.delayed(Duration.zero);
      progress.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withAction(
      icon: Icons.folder_outlined,
      title: '下载位置',
      value: _isChanging ? '迁移中...' : _displayValue,
      subtitle: const Text('更改后会迁移现有下载内容'),
      onTap: _showActions,
    );
  }
}

enum _DownloadPathAction { choose, reset }

class _MigrationProgressDialog extends StatelessWidget {
  const _MigrationProgressDialog({required this.progress});

  final ValueListenable<DownloadMigrationProgress> progress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('正在迁移下载内容'),
        content: SizedBox(
          width: 360,
          child: ValueListenableBuilder<DownloadMigrationProgress>(
            valueListenable: progress,
            builder: (_, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: value.fraction),
                const SizedBox(height: 14),
                Text(_stageText(value.stage)),
                if (value.currentFolder != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    value.currentFolder!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (value.totalBytes > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_formatBytes(value.copiedBytes)} / ${_formatBytes(value.totalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stageText(DownloadMigrationStage stage) => switch (stage) {
    DownloadMigrationStage.preparing => '正在统计文件...',
    DownloadMigrationStage.copying => '正在复制文件...',
    DownloadMigrationStage.verifying => '正在校验文件...',
    DownloadMigrationStage.cleaning => '正在清理原位置...',
  };

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final index = min((log(bytes) / log(1024)).floor(), units.length - 1);
    final value = bytes / pow(1024, index);
    return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }
}
