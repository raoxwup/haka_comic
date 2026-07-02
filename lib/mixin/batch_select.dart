import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/widgets/toast.dart';

mixin BatchSelectMixin<T extends StatefulWidget> on State<T> {
  bool isSelecting = false;
  Set<String> selectedCids = {};
  bool isDownloading = false;

  void enterSelectionMode(String uid) {
    setState(() {
      isSelecting = true;
      selectedCids = {uid};
    });
  }

  void exitSelectionMode() {
    setState(() {
      isSelecting = false;
      selectedCids = {};
    });
  }

  void toggleItem(String uid) {
    setState(() {
      if (selectedCids.contains(uid)) {
        selectedCids.remove(uid);
      } else {
        selectedCids.add(uid);
      }
    });
  }

  void selectAll(List<ComicBase> comics) {
    setState(() => selectedCids = comics.map((c) => c.uid).toSet());
  }

  void invertSelection(List<ComicBase> comics) {
    setState(() {
      final all = comics.map((c) => c.uid).toSet();
      selectedCids = all.difference(selectedCids);
    });
  }

  Future<void> batchDownload(List<ComicBase> allComics) async {
    if (selectedCids.isEmpty) return;

    setState(() => isDownloading = true);

    final selected = allComics
        .where((c) => selectedCids.contains(c.uid))
        .toList();
    int successCount = 0;
    int failCount = 0;

    try {
      final results = await Future.wait(
        selected.map((comic) async {
          try {
            final chapters = await fetchChapters(comic.uid);
            if (chapters.isEmpty) return false;

            BackgroundDownloader.addTask(
              ComicDownloadTask(
                comic: DownloadComic(
                  id: comic.uid,
                  title: comic.title,
                  cover: comic.thumb.url,
                  image: comic.thumb,
                ),
                chapters: chapters
                    .map(
                      (c) => DownloadChapter(
                        id: c.uid,
                        title: c.title,
                        order: c.order,
                      ),
                    )
                    .toList(),
              ),
            );
            return true;
          } catch (e) {
            Log.e('Batch download failed: ${comic.title}', error: e);
            return false;
          }
        }),
      );

      successCount = results.where((r) => r).length;
      failCount = results.where((r) => !r).length;
    } catch (e) {
      Log.e('Batch download error', error: e);
    }

    if (mounted) {
      Toast.show(
        message: failCount == 0
            ? '已添加 $successCount 个下载任务'
            : '成功 $successCount 个，失败 $failCount 个',
      );
      setState(() {
        isSelecting = false;
        selectedCids = {};
        isDownloading = false;
      });
    }
  }
}
