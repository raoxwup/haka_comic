import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/rust/api/compress.dart';
import 'package:haka_comic/rust/api/simple.dart';
import 'package:haka_comic/utils/android_download_saver.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/loader.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/slide_transition_x.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

enum ExportFileType { pdf, zip }

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  List<ComicDownloadTask> tasks = [];
  late final StreamSubscription _subscription;
  bool _isSelecting = false;
  Set<String> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _subscription = BackgroundDownloader.streamController.stream.listen(
      (event) => setState(() {
        tasks = event;
      }),
    );
    BackgroundDownloader.getTasks();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  List<ComicDownloadTask> get _selectedTasks {
    return tasks
        .where((task) => _selectedTaskIds.contains(task.comic.id))
        .toList();
  }

  void clearTasks() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('是否删除选中的下载任务？'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      BackgroundDownloader.deleteTasks(_selectedTaskIds.toList());
      close();
    }
  }

  Future<void> exportTasksForDesktop({required ExportFileType type}) async {
    try {
      String? selectedDirectoryPath = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectoryPath == null) {
        Toast.show(message: "未选择导出目录");
        return;
      }

      if (mounted) {
        Loader.show(context);
      }

      final downloadPath = await getDownloadDirectory();

      for (var task in _selectedTasks) {
        final sourceDirPath = p.join(downloadPath, task.comic.title.legalized);

        final destPath = p.join(
          selectedDirectoryPath,
          '${task.comic.title.legalized}.${type.name}',
        );

        switch (type) {
          case ExportFileType.pdf:
            await exportPdf(
              sourceFolderPath: sourceDirPath,
              outputPdfPath: destPath,
            );
          case ExportFileType.zip:
            await compress(
              sourceFolderPath: sourceDirPath,
              outputZipPath: destPath,
              compressionMethod: CompressionMethod.stored,
            );
        }
      }

      Toast.show(message: "导出成功");
    } catch (e) {
      Log.error("export comic failed", e);
      Toast.show(message: "导出失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      close();
    }
  }

  Future<void> exportTasksForIos({required ExportFileType type}) async {
    final cacheDir = await getApplicationCacheDirectory();
    try {
      if (mounted) {
        Loader.show(context);
      }

      final downloadPath = await getDownloadDirectory();

      for (var task in _selectedTasks) {
        final sourcePath = p.join(downloadPath, task.comic.title.legalized);

        final destPath = p.join(
          cacheDir.path,
          '${task.comic.title.legalized}.${type.name}',
        );

        switch (type) {
          case ExportFileType.pdf:
            await exportPdf(
              sourceFolderPath: sourcePath,
              outputPdfPath: destPath,
            );
          case ExportFileType.zip:
            await compress(
              sourceFolderPath: sourcePath,
              outputZipPath: destPath,
              compressionMethod: CompressionMethod.stored,
            );
        }
      }

      final params = ShareParams(
        files: _selectedTasks.map((task) {
          return XFile(
            p.join(cacheDir.path, '${task.comic.title.legalized}.${type.name}'),
          );
        }).toList(),
      );

      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {
        Toast.show(message: "操作成功");
      }
    } catch (e) {
      Log.error("export comic failed", e);
      Toast.show(message: "操作失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      close();
    }
  }

  Future<void> exportTasksForAndroid({required ExportFileType type}) async {
    final cacheDir = await getApplicationCacheDirectory();
    try {
      final version = await AndroidDownloadSaver.getAndroidVersion();

      if (version <= 28) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) openAppSettings();
          Toast.show(message: "没有必要的储存权限");
          return;
        }
      }

      if (mounted) {
        Loader.show(context);
      }

      final downloadPath = await getDownloadDirectory();

      for (var task in _selectedTasks) {
        final sourcePath = p.join(downloadPath, task.comic.title.legalized);

        final fileName = '${task.comic.title.legalized}.${type.name}';

        final destPath = p.join(cacheDir.path, fileName);

        switch (type) {
          case ExportFileType.pdf:
            await exportPdf(
              sourceFolderPath: sourcePath,
              outputPdfPath: destPath,
            );
          case ExportFileType.zip:
            await compress(
              sourceFolderPath: sourcePath,
              outputZipPath: destPath,
              compressionMethod: CompressionMethod.stored,
            );
        }

        await AndroidDownloadSaver.saveToDownloads(
          filePath: destPath,
          fileName: fileName,
        );
      }

      Toast.show(message: "导出成功");
    } catch (e) {
      Log.error("export comic failed", e);
      Toast.show(message: "导出失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      close();
    }
  }

  VoidCallback? exportFile({required ExportFileType type}) {
    final isCanPress = (_selectedTaskIds.isEmpty || !isAllCompleted);
    if (isCanPress) {
      return null;
    }
    return isAndroid
        ? () => exportTasksForAndroid(type: type)
        : isDesktop
        ? () => exportTasksForDesktop(type: type)
        : () => exportTasksForIos(type: type);
  }

  void close() {
    setState(() {
      _isSelecting = false;
      _selectedTaskIds.clear();
    });
  }

  bool get isAllCompleted => _selectedTasks.every(
    (task) => task.status == DownloadTaskStatus.completed,
  );

  final entries = <ContextMenuEntry>[
    const MenuItem(label: Text('复制标题'), icon: Icon(Icons.copy), value: 'copy'),
    const MenuItem(
      label: Text('选中该项'),
      icon: Icon(Icons.check),
      value: 'select',
    ),
  ];

  late final menu = ContextMenu(
    entries: entries,
    padding: const EdgeInsets.all(8.0),
  );

  Future<void> _onContextMenuItemPress(
    String value,
    ComicDownloadTask task,
  ) async {
    switch (value) {
      case 'copy':
        final title = task.comic.title;
        await Clipboard.setData(ClipboardData(text: title));
        Toast.show(message: '已复制');
        break;
      case 'select':
        setState(() {
          _isSelecting = true;
          _selectedTaskIds.add(task.comic.id);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSelecting) {
          close();
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: _isSelecting
            ? _SelectionAppBar(
                selectedCount: _selectedTaskIds.length,
                onClose: close,
                onDeselectAll: () => setState(() => _selectedTaskIds.clear()),
                onSelectAll: () => setState(
                  () => _selectedTaskIds = tasks.map((e) => e.comic.id).toSet(),
                ),
                onInvertSelection: () {
                  final allIds = tasks.map((e) => e.comic.id).toSet();
                  setState(() {
                    _selectedTaskIds = allIds.difference(_selectedTaskIds);
                  });
                },
              )
            : _NormalAppBar(
                onEnterSelection: () => setState(() => _isSelecting = true),
              ),
        body: CustomScrollView(
          slivers: [
            if (tasks.isEmpty) const SliverToBoxAdapter(child: Empty()),
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: UiMode.m1(context)
                    ? width
                    : UiMode.m2(context)
                    ? width / 2
                    : width / 3,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isSelected = _selectedTaskIds.contains(task.comic.id);
                return _DownloadTaskItem(
                  task: task,
                  isSelecting: _isSelecting,
                  isSelected: isSelected,
                  contextMenu: menu,
                  onTap: () {
                    if (_isSelecting) {
                      setState(() {
                        if (isSelected) {
                          _selectedTaskIds.remove(task.comic.id);
                        } else {
                          _selectedTaskIds.add(task.comic.id);
                        }
                      });
                    }
                  },
                  onItemSelected: _onContextMenuItemPress,
                );
              },
              itemCount: tasks.length,
            ),
          ],
        ),
        persistentFooterButtons: _isSelecting
            ? [
                FilledButton.tonalIcon(
                  onPressed: exportFile(type: ExportFileType.pdf),
                  label: const Text('PDF'),
                  icon: const Icon(Icons.picture_as_pdf),
                ),
                FilledButton.tonalIcon(
                  onPressed: exportFile(type: ExportFileType.zip),
                  label: const Text('ZIP'),
                  icon: const Icon(Icons.folder_zip),
                ),
                FilledButton.tonalIcon(
                  onPressed: _selectedTaskIds.isEmpty ? null : clearTasks,
                  label: const Text('删除'),
                  icon: const Icon(Icons.delete_forever),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colorScheme.error,
                    foregroundColor: context.colorScheme.onError,
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onDeselectAll;
  final VoidCallback onSelectAll;
  final VoidCallback onInvertSelection;

  const _SelectionAppBar({
    required this.selectedCount,
    required this.onClose,
    required this.onDeselectAll,
    required this.onSelectAll,
    required this.onInvertSelection,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) {
          return SlideTransitionX(
            position: animation,
            direction: AxisDirection.down,
            child: child,
          );
        },
        child: Text('$selectedCount', key: ValueKey(selectedCount)),
      ),
      leading: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      actions: [
        IconButton(onPressed: onDeselectAll, icon: const Icon(Icons.deselect)),
        IconButton(onPressed: onSelectAll, icon: const Icon(Icons.select_all)),
        IconButton(
          onPressed: onInvertSelection,
          icon: const Icon(Icons.repeat),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onEnterSelection;
  const _NormalAppBar({required this.onEnterSelection});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('我的下载'),
      actions: [
        IconButton(
          onPressed: onEnterSelection,
          icon: const Icon(Icons.checklist_rtl),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DownloadTaskItem extends StatelessWidget {
  final ComicDownloadTask task;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function(String, ComicDownloadTask) onItemSelected;
  final ContextMenu contextMenu;

  const _DownloadTaskItem({
    required this.task,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onItemSelected,
    required this.contextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ContextMenuRegion(
      contextMenu: contextMenu,
      enableDefaultGestures: !isSelecting,
      onItemSelected: (value) => onItemSelected(value!, task),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: context.colorScheme.secondaryContainer.withValues(
                    alpha: 0.65,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            children: [
              BaseImage(url: task.comic.cover, aspectRatio: 90 / 130),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.comic.title,
                      style: context.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (task.status.isOperable)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              task.status.iconAndAction.action(task.comic.id);
                            },
                            icon: Icon(task.status.iconAndAction.icon),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        Text(
                          task.status.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${task.completed} / ${task.total}',
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(99),
                      value: task.total == 0
                          ? null
                          : task.completed / task.total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
