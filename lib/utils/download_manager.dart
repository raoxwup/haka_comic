import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void _downloadIsolateEntry(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final List<ComicDownloadTask> tasks = [];
  final dio = Dio();
  final cancelToken = CancelToken();

  Future<void> downloadImage(String url, String path) async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        await dio.download(url, path, cancelToken: cancelToken);
        return;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void download(ComicDownloadTask task) async {
    int i = 0;
    final dirPath =
        (await getDownloadsDirectory())?.path ??
        (await getApplicationDocumentsDirectory()).path;

    for (var chapter in task.chapters) {
      for (var image in chapter.images) {
        if (i++ < task.completed) {
          continue;
        }
        final path = p.join(
          dirPath,
          'comics',
          task.comic.title,
          chapter.title,
          image.originalName,
        );
        await downloadImage(image.url, path);
        task.completed++;
      }
    }
  }

  Future<void> chapterInitialize(DownloadChapter chapter, String id) async {
    if (chapter.images.isNotEmpty) return;
    final response = await fetchChapterImages(
      FetchChapterImagesPayload(id: id, order: chapter.order),
    );
    chapter.images.addAll(response.map((e) => e.media));
  }

  Future<void> update(ComicDownloadTask task) async {
    task.total = 0;
    for (var chapter in task.chapters) {
      await chapterInitialize(chapter, task.comic.id);
      task.total += chapter.images.length;
    }
    download(task);
  }

  void add(ComicDownloadTask task) {
    final index = tasks.indexWhere((t) => task.comic.id == t.comic.id);
    if (index != -1) {
      tasks[index].chapters.addAll(task.chapters);
      update(tasks[index]);
    } else {
      tasks.add(task);
      update(task);
    }
  }

  receivePort.listen((message) {
    if (message is ComicDownloadTask) {
      add(message);
    }
  });
}

class DownloadManager {
  static final ReceivePort mainReceivePort = ReceivePort();
  static late final Isolate workerIsolate;
  static late final SendPort workerSendPort;

  static Future<void> initialize() async {
    final completer = Completer<void>();
    workerIsolate = await Isolate.spawn(
      _downloadIsolateEntry,
      mainReceivePort.sendPort,
    );

    mainReceivePort.listen((message) {
      if (message is SendPort) {
        workerSendPort = message;
        completer.complete();
      }
    });

    return completer.future;
  }
}

class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;

  int total = 0;
  int completed = 0;

  ComicDownloadTask({required this.comic, required this.chapters});
}

class DownloadChapter extends Chapter {
  /// 这个章节的所有图片
  final List<ImageDetail> images = [];

  DownloadChapter({
    required super.uid,
    required super.title,
    required super.order,
    required super.updated_at,
    required super.id,
  });
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
