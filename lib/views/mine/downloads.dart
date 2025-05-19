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

  final _iconMap = {
    DownloadTaskStatus.paused: Icons.play_arrow,
    DownloadTaskStatus.downloading: Icons.pause,
    DownloadTaskStatus.error: Icons.refresh,
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

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return Scaffold(
      appBar: AppBar(title: const Text('我的下载')),
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
                                      onPressed: () {},
                                      icon: Icon(_iconMap[task.status]!),
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
                    ],
                  ),
                ),
              );
            },
            itemCount: tasks.length,
          ),
        ],
      ),
    );
  }
}
