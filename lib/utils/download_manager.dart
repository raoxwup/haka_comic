import 'package:dio/dio.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:path_provider/path_provider.dart';

class ComicDownloadManager {
  static List<ComicDownloadTask> tasks = [];

  static void add(ComicDownloadTask task) {
    final index = tasks.indexWhere((t) => task.comic.id == t.comic.id);
    if (index != -1) {
      tasks[index].chapters.addAll(task.chapters);
    } else {
      tasks.add(task);
    }
  }

  static void remove(ComicDownloadTask task) {
    tasks.remove(task);
  }
}

class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;

  ///  获取需要下载的图片总数
  Future<int> getTotalDownloads() async {
    int total = 0;
    for (var chapter in chapters) {
      if (chapter.images.isEmpty) {
        await chapter.inventoryImages(comic.id);
      }
      total += chapter.images.length;
    }
    return total;
  }

  Future<void> download() async {
    for (var chapter in chapters) {
      for (var image in chapter.images) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final filePath =
            '${documentsDir.path}/comics/${comic.title}/${chapter.title}/${image.originalName}';
        await Dio().download(image.url, filePath);
        chapter.downloadedImages.add(image);
      }
    }
  }

  const ComicDownloadTask({required this.comic, required this.chapters});
}

class DownloadComic {
  final String id;
  final String title;
  final String cover;

  const DownloadComic({
    required this.id,
    required this.title,
    required this.cover,
  });
}

class DownloadChapter extends Chapter {
  /// 需要下载的图片
  final List<ImageDetail> images = [];

  /// 已下载的图片
  final List<ImageDetail> downloadedImages = [];

  /// 获取需要下载的图片
  Future<List<ImageDetail>> inventoryImages(String id) async {
    images.clear();
    final data = await fetchChapterImages(
      FetchChapterImagesPayload(id: id, order: order),
    );
    images.addAll(data.map((item) => item.media).toList());
    return images;
  }

  DownloadChapter({
    required super.uid,
    required super.title,
    required super.order,
    required super.updated_at,
    required super.id,
  });
}
