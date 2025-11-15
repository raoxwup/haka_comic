import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/widgets/toast.dart';

class Downloader extends StatefulWidget {
  const Downloader({
    super.key,
    required this.chapters,
    required this.downloadComic,
  });

  final List<Chapter> chapters;
  final DownloadComic downloadComic;

  @override
  State<Downloader> createState() => _DownloaderState();
}

class _DownloaderState extends State<Downloader> {
  /// 选中的章节
  List<Chapter> selectedChapters = [];

  /// 已下载的章节Id
  Set<String> downloadedChapterIds = {};

  Future<void> initDownloadedChapters() async {
    final downloadTaskHelper = DownloadTaskHelper();
    await downloadTaskHelper.initialize();
    final downloadChapters = await downloadTaskHelper.getDownloadChapters(
      widget.downloadComic.id,
    );
    setState(() {
      downloadedChapterIds = downloadChapters
          .map((chapter) => chapter.id)
          .toSet();
    });
  }

  void startDownload(List<Chapter> chapters) {
    if (chapters.isEmpty) return;
    DownloadManager.addTask(
      ComicDownloadTask(
        comic: widget.downloadComic,
        chapters: chapters
            .map(
              (chapter) => DownloadChapter(
                id: chapter.uid,
                title: chapter.title,
                order: chapter.order,
              ),
            )
            .toList(),
      ),
    );
    context.pop();
    Toast.show(message: "已添加到下载队列");
  }

  @override
  void initState() {
    super.initState();
    initDownloadedChapters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: ListView.builder(
        itemCount: widget.chapters.length,
        itemBuilder: (context, index) {
          final chapter = widget.chapters[index];
          final isDownloaded = downloadedChapterIds.contains(chapter.uid);
          final selected = selectedChapters.contains(chapter);
          return ListTile(
            enabled: !isDownloaded,
            title: Text(chapter.title),
            trailing: Checkbox(
              value: selected || isDownloaded,
              onChanged: isDownloaded
                  ? null
                  : (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedChapters.add(chapter);
                        } else {
                          selectedChapters.remove(chapter);
                        }
                      });
                    },
            ),
            onTap: () {
              setState(() {
                if (selected) {
                  selectedChapters.remove(chapter);
                } else {
                  selectedChapters.add(chapter);
                }
              });
            },
          );
        },
      ),
      persistentFooterButtons: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final canDownloadChapters = widget.chapters
                      .where(
                        (chapter) =>
                            !downloadedChapterIds.contains(chapter.uid),
                      )
                      .toList();
                  return TextButton(
                    onPressed: canDownloadChapters.isNotEmpty
                        ? () {
                            startDownload(canDownloadChapters);
                          }
                        : null,
                    child: const Text('下载全部'),
                  );
                },
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: selectedChapters.isNotEmpty
                    ? () {
                        startDownload(selectedChapters);
                      }
                    : null,
                child: const Text('下载所选'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
