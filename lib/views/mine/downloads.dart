import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/rust/api/compress.dart';
import 'package:haka_comic/rust/api/simple.dart';
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
import 'package:share_plus/share_plus.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as downloadsfolder;

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

  final Map<DownloadTaskStatus, Map<String, dynamic>> _iconMap = {
    DownloadTaskStatus.paused: {
      "icon": Icons.play_arrow,
      "action": (String comicId) {
        BackgroundDownloader.resumeTask(comicId);
      },
    },
    DownloadTaskStatus.downloading: {
      "icon": Icons.pause,
      "action": (String comicId) {
        BackgroundDownloader.pauseTask(comicId);
      },
    },
    DownloadTaskStatus.error: {
      "icon": Icons.refresh,
      "action": (String comicId) {
        BackgroundDownloader.resumeTask(comicId);
      },
    },
  };

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

        await downloadsfolder.copyFileIntoDownloadFolder(destPath, fileName);
      }

      Toast.show(message: "操作成功");
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

  late TapDownDetails _tapDownDetails;

  void _showContextMenu(
    BuildContext context,
    Offset offset,
    ComicDownloadTask task,
  ) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final screenSize = overlay.size;

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy, 1, 1),
      Offset.zero & screenSize,
    );

    // 显示菜单
    final String? result = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: ListTile(leading: Icon(Icons.copy), title: Text('复制标题')),
        ),
        const PopupMenuItem(
          value: 'select',
          child: ListTile(leading: Icon(Icons.check), title: Text('选择')),
        ),
      ],
      elevation: 4,
    );

    switch (result) {
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

  // define your context menu entries
  final entries = <ContextMenuEntry>[
    MenuItem(
      label: const Text('Copy'),
      icon: const Icon(Icons.copy),
      onSelected: (value) {
        // implement copy
      },
    ),
    MenuItem(
      enabled: false, // disable this item
      label: const Text('Cut'),
      icon: const Icon(Icons.cut),
      onSelected: (value) {
        // implement cut
      },
    ),
    MenuItem(
      label: const Text('Paste'),
      icon: const Icon(Icons.paste),
      onSelected: (value) {
        // implement paste
      },
    ),
    const MenuDivider(),
    MenuItem.submenu(
      label: const Text('Edit'),
      icon: const Icon(Icons.edit),
      items: [
        MenuItem(
          label: const Text('Undo'),
          value: "Undo",
          icon: const Icon(Icons.undo),
          onSelected: (value) {
            // implement undo
          },
        ),
        MenuItem(
          label: const Text('Redo'),
          value: 'Redo',
          icon: const Icon(Icons.redo),
          onSelected: (value) {
            // implement redo
          },
        ),
      ],
    ),
  ];

  // initialize a context menu
  late final menu = ContextMenu(
    entries: entries,
    padding: const EdgeInsets.all(8.0),
  );

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
        appBar: AppBar(
          title: _isSelecting
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return SlideTransitionX(
                      position: animation,
                      direction: AxisDirection.down,
                      child: child,
                    );
                  },
                  child: Text(
                    '${_selectedTaskIds.length}',
                    key: ValueKey(_selectedTaskIds.length),
                  ),
                )
              : const Text('我的下载'),
          leading: _isSelecting
              ? IconButton(
                  onPressed: () => close(),
                  icon: const Icon(Icons.close),
                )
              : null,
          actions: _isSelecting
              ? [
                  IconButton(
                    onPressed: () => setState(() => _selectedTaskIds.clear()),
                    icon: const Icon(Icons.deselect),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () =>
                          _selectedTaskIds.addAll(tasks.map((e) => e.comic.id)),
                    ),
                    icon: const Icon(Icons.select_all),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final allIds = tasks.map((e) => e.comic.id).toSet();
                        _selectedTaskIds = _selectedTaskIds
                            .difference(allIds)
                            .union(allIds.difference(_selectedTaskIds));
                      });
                    },
                    icon: const Icon(Icons.repeat),
                  ),
                ]
              : [
                  IconButton(
                    onPressed: () => setState(() => _isSelecting = true),
                    icon: const Icon(Icons.checklist_rtl),
                  ),
                ],
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
                return ContextMenuRegion(
                  contextMenu: menu,
                  child: InkWell(
                    key: ValueKey(task.comic.id),
                    onTapDown: (details) => _tapDownDetails = details,
                    // onLongPress: _isSelecting
                    //     ? null
                    //     : () {
                    //         _showContextMenu(
                    //           context,
                    //           _tapDownDetails.globalPosition,
                    //           task,
                    //         );
                    //       },
                    onTap: () {
                      if (_isSelecting) {
                        setState(() {
                          if (_selectedTaskIds.contains(task.comic.id)) {
                            _selectedTaskIds.remove(task.comic.id);
                          } else {
                            _selectedTaskIds.add(task.comic.id);
                          }
                        });
                        return;
                      }
                      Toast.show(message: "功能开发中...");
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      decoration: _selectedTaskIds.contains(task.comic.id)
                          ? BoxDecoration(
                              color: context.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        spacing: 8,
                        children: [
                          BaseImage(
                            url: task.comic.cover,
                            aspectRatio: 90 / 130,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    task.comic.title,
                                    style: context.textTheme.titleSmall,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  if (_iconMap.containsKey(task.status))
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _iconMap[task.status]!["action"](
                                              task.comic.id,
                                            );
                                          },
                                          icon: Icon(
                                            _iconMap[task.status]!["icon"],
                                          ),
                                        ),
                                      ],
                                    ),
                                  Row(
                                    children: [
                                      Text(
                                        task.status.displayName,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  context.colorScheme.primary,
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
                          ),
                        ],
                      ),
                    ),
                  ),
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
