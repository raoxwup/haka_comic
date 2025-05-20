import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/toast.dart';

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
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

  void clearTasks() {
    DownloadManager.deleteTasks(_selectedTasks.map((e) => e.comic.id).toList());
    setState(() {
      tasks.removeWhere((t) => _selectedTasks.contains(t));
    });
    close();
  }

  void close() {
    setState(() {
      _isSelecting = false;
      _selectedTasks = [];
    });
  }

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
                            spacing: 5,
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${task.completed} / ${task.total}',
                                    style: context.textTheme.bodySmall,
                                  ),
                                  if (_iconMap.containsKey(task.status))
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
                  onPressed: clearTasks,
                  label: const Text('删除'),
                  icon: const Icon(Icons.delete_forever),
                ),
              ]
              : null,
    );
  }
}
