import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/download_manager.dart';

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
  Set<String> selectedChapterIds = {};

  void startDownload(List<Chapter> chapters) async {
    print(jsonEncode(chapters));
    await DownloadManager.initialize();
    DownloadManager.workerSendPort.send(
      ComicDownloadTask(
        comic: widget.downloadComic,
        chapters:
            chapters
                .map(
                  (chapter) => DownloadChapter(
                    uid: chapter.uid,
                    title: chapter.title,
                    order: chapter.order,
                    updated_at: chapter.updated_at,
                    id: chapter.id,
                  ),
                )
                .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('下载')),
      body: ListView.builder(
        itemCount: widget.chapters.length,
        itemBuilder: (context, index) {
          final chapter = widget.chapters[index];
          return ListTile(
            title: Text(chapter.title),
            trailing: Checkbox(
              value: selectedChapterIds.contains(chapter.uid),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedChapterIds.add(chapter.uid);
                  } else {
                    selectedChapterIds.remove(chapter.uid);
                  }
                });
              },
            ),
            onTap: () {
              setState(() {
                if (selectedChapterIds.contains(chapter.uid)) {
                  selectedChapterIds.remove(chapter.uid);
                } else {
                  selectedChapterIds.add(chapter.uid);
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
              child: TextButton(
                onPressed: () {
                  startDownload(widget.chapters);
                },
                child: const Text('下载全部'),
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed:
                    selectedChapterIds.isNotEmpty
                        ? () {
                          List<Chapter> selectedChapters = [];
                          for (var chapterId in selectedChapterIds) {
                            final chapter = widget.chapters.firstWhere(
                              (c) => c.uid == chapterId,
                            );
                            selectedChapters.add(chapter);
                          }
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
