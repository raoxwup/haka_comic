import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/loader.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path/path.dart' as p;

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

String downloadTaskStatusToString(DownloadTaskStatus status) {
  return switch (status) {
    DownloadTaskStatus.queued => "等待中",
    DownloadTaskStatus.downloading => "下载中",
    DownloadTaskStatus.paused => "已暂停",
    DownloadTaskStatus.completed => "已完成",
    DownloadTaskStatus.error => "下载失败",
  };
}

class _DownloadsState extends State<Downloads> {
  List<ComicDownloadTask> tasks = [];
  late final StreamSubscription _subscription;
  bool _isSelecting = false;
  List<ComicDownloadTask> _selectedTasks = [];

  final Map<DownloadTaskStatus, Map<String, dynamic>> _iconMap = {
    DownloadTaskStatus.paused: {
      "icon": Icons.play_arrow,
      "action": (String comicId) {
        DownloadManager.resumeTask(comicId);
      },
    },
    DownloadTaskStatus.downloading: {
      "icon": Icons.pause,
      "action": (String comicId) {
        DownloadManager.pauseTask(comicId);
      },
    },
    DownloadTaskStatus.error: {
      "icon": Icons.refresh,
      "action": (String comicId) {
        DownloadManager.resumeTask(comicId);
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _subscription = DownloadManager.streamController.stream.listen(
      (event) => setState(() {
        tasks = event;
      }),
    );
    DownloadManager.getTasks();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
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
      DownloadManager.deleteTasks(
        _selectedTasks.map((e) => e.comic.id).toList(),
      );
      setState(() {
        tasks.removeWhere((t) => _selectedTasks.contains(t));
      });
      close();
    }
  }

  void exportTasks() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        Toast.show(message: "未选择导出目录");
        return;
      }

      if (mounted) {
        Loader.show(context);
      }

      final downloadPath = await getDownloadDirectory();

      for (var task in _selectedTasks) {
        final sourceDir = Directory(
          p.join(downloadPath, sanitizeFileName(task.comic.title)),
        );

        final destDir = Directory(
          p.join(selectedDirectory, sanitizeFileName(task.comic.title)),
        );

        await copyDirectory(sourceDir, destDir);
      }

      Toast.show(message: "导出成功");
    } catch (e) {
      Toast.show(message: "导出失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      close();
    }
  }

  void close() {
    setState(() {
      _isSelecting = false;
      _selectedTasks = [];
    });
  }

  bool get isAllCompleted => _selectedTasks.every(
    (task) => task.status == DownloadTaskStatus.completed,
  );

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的下载'),
        actions:
            _isSelecting
                ? [
                  IconButton(
                    onPressed: () => setState(() => _selectedTasks = []),
                    icon: const Icon(Icons.deselect),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedTasks = tasks),
                    icon: const Icon(Icons.select_all),
                  ),
                  IconButton(onPressed: close, icon: const Icon(Icons.close)),
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
              maxCrossAxisExtent:
                  UiMode.m1(context)
                      ? width
                      : UiMode.m2(context)
                      ? width / 2
                      : width / 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return InkWell(
                key: ValueKey(task.comic.id),
                onTap: () {
                  if (_isSelecting) {
                    setState(() {
                      if (_selectedTasks.contains(task)) {
                        _selectedTasks.remove(task);
                      } else {
                        _selectedTasks.add(task);
                      }
                    });
                    return;
                  }
                  Toast.show(message: "功能开发中...");
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    spacing: 8,
                    children: [
                      BaseImage(url: task.comic.cover, aspectRatio: 14 / 19),
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
                                maxLines: 2,
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
                                    downloadTaskStatusToString(task.status),
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
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
                                value:
                                    task.total == 0
                                        ? null
                                        : task.completed / task.total,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isSelecting)
                        Checkbox(
                          value: _selectedTasks.contains(task),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedTasks.add(task);
                              } else {
                                _selectedTasks.remove(task);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            itemCount: tasks.length,
          ),
        ],
      ),
      persistentFooterButtons:
          _isSelecting
              ? [
                FilledButton.tonalIcon(
                  onPressed:
                      (_selectedTasks.isEmpty || !isAllCompleted)
                          ? null
                          : exportTasks,
                  label: const Text('导出'),
                  icon: const Icon(Icons.drive_file_move),
                ),
                FilledButton.tonalIcon(
                  onPressed: _selectedTasks.isEmpty ? null : clearTasks,
                  label: const Text('删除'),
                  icon: const Icon(Icons.delete_forever),
                ),
              ]
              : null,
    );
  }
}
