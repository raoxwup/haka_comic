import 'dart:async';
import 'package:dio/dio.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:path/path.dart' as p;

class ComicDownloadManager {
  static List<ComicDownloadTask> tasks = [];

  static void add(ComicDownloadTask task) {
    final index = tasks.indexWhere((t) => task.comic.id == t.comic.id);
    if (index != -1) {
      tasks[index].chapters.addAll(task.chapters);
      tasks[index].update();
    } else {
      tasks.add(task);
      task.update();
    }
  }

  static void remove(ComicDownloadTask task) {
    task.cancel();
    tasks.remove(task);
  }
}

class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;
  final CancelToken _cancelToken = CancelToken();
  final Dio _dio = Dio();

  int total = 0;
  int completed = 0;

  void update() async {
    total = 0;
    for (var chapter in chapters) {
      await chapter.initialize(comic.id);
      total += chapter.images.length;
    }
    download();
  }

  void download() async {
    int i = 0;
    for (var chapter in chapters) {
      for (var image in chapter.images) {
        if (i++ < completed) {
          continue;
        }
        final path = p.join(
          SetupConf.documentsPath,
          'comics',
          comic.title,
          chapter.title,
          image.originalName,
        );
        await _downloadImage(image.url, path);
        completed++;
      }
    }
  }

  Future<void> _downloadImage(String url, String path) async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        await _dio.download(url, path, cancelToken: _cancelToken);
        return;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void cancel() {
    _cancelToken.cancel('用户取消');
  }

  ComicDownloadTask({required this.comic, required this.chapters});
}

class DownloadChapter extends Chapter {
  /// 这个章节的所有图片
  List<ImageDetail> images = [];

  Future<void> initialize(String id) async {
    if (images.isNotEmpty) return;
    final response = await fetchChapterImages(
      FetchChapterImagesPayload(id: id, order: order),
    );
    images.addAll(response.map((e) => e.media));
  }

  DownloadChapter({
    required super.uid,
    required super.title,
    required super.order,
    required super.updated_at,
    required super.id,
  });

  DownloadChapter.fromJson(Map<String, dynamic> json)
    : super(
        uid: json['_id'] as String,
        title: json['title'] as String,
        order: (json['order'] as num).toInt(),
        updated_at: json['updated_at'] as String,
        id: json['id'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
    '_id': uid,
    'title': title,
    'order': order,
    'updated_at': updated_at,
    'id': id,
  };
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

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'cover': cover};

  factory DownloadComic.fromJson(Map<String, dynamic> json) {
    return DownloadComic(
      id: json['id'] as String,
      title: json['title'] as String,
      cover: json['cover'] as String,
    );
  }
}

enum DownloadStatus { queued, downloading, paused, completed, failed }
