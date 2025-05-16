import 'package:flutter/material.dart';
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/base_image.dart';

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  List<ComicDownloadTask> tasks = [];

  @override
  void initState() {
    super.initState();
    DownloadManager.streamController.stream.listen(
      (event) => setState(() {
        tasks = event;
      }),
    );
    DownloadManager.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
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
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return SizedBox(
                key: ValueKey(task.comic.id),
                width: double.infinity,
                height: 170,
                child: Row(
                  spacing: 8,
                  children: [
                    BaseImage(url: task.comic.cover, aspectRatio: 13 / 17),
                    Expanded(
                      child: Column(
                        spacing: 5,
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
                          LinearProgressIndicator(
                            value:
                                task.total == 0
                                    ? null
                                    : task.completed / task.total,
                            semanticsLabel:
                                task.total == 0
                                    ? 'Loading...'
                                    : '${task.completed} / ${task.total}',
                          ),
                        ],
                      ),
                    ),
                  ],
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
