import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _downloadIsolateEntry((SendPort, RootIsolateToken) args) {
  final (sendPort, rootToken) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is ComicDownloadTask) {
      _ComicDownloader.add(message);
    }
  });
}

class _ComicDownloader {
  static final List<ComicDownloadTask> tasks = [];
  static final dio = Dio();

  static final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};

  static Future<void> _downloadImage(
    String url,
    String path,
    CancelToken? cancelToken,
  ) async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        await dio.download(url, path, cancelToken: cancelToken);
        return;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 2 * i));
      }
    }
  }

  static Future<void> download(ComicDownloadTask task) async {
    int i = 0;
    final dirPath = (await getApplicationDocumentsDirectory()).path;
    for (var chapter in task.chapters) {
      for (var image in chapter.images) {
        if (i++ < task.completed) {
          continue;
        }
        final path = p.join(
          dirPath,
          'comics',
          sanitizeFileName(task.comic.title),
          sanitizeFileName(chapter.title),
          image.originalName,
        );
        await _downloadImage(image.url, path, _cancelTokens[task.comic.id]);
        task.completed++;
      }
    }
  }

  static Future<void> chapterInitialize(
    DownloadChapter chapter,
    String id,
  ) async {
    if (chapter.images.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('token is null');
    }

    final response = await fetchChapterImagesIsolate(
      FetchChapterImagesPayload(id: id, order: chapter.order),
      token,
    );
    chapter.images.addAll(response.map((e) => e.media));
  }

  static Future<void> update(ComicDownloadTask task) async {
    task.total = 0;
    for (var chapter in task.chapters) {
      await chapterInitialize(chapter, task.comic.id);
      task.total += chapter.images.length;
    }
    download(task);
  }

  static void add(ComicDownloadTask task) {
    final index = tasks.indexWhere((t) => task.comic.id == t.comic.id);
    if (index != -1) {
      tasks[index].chapters.addAll(task.chapters);
      update(tasks[index]);
    } else {
      _cancelTokens[task.comic.id] = CancelToken();
      tasks.add(task);
      update(task);
    }
  }

  static void pause(ComicDownloadTask task) {
    _cancelTokens[task.comic.id]?.cancel();
    _cancelTokens[task.comic.id] = CancelToken();
  }
}

class DownloadManager {
  static final ReceivePort _mainReceivePort = ReceivePort();
  static late final Isolate _workerIsolate;
  static late final SendPort _workerSendPort;
  static final _rootToken = RootIsolateToken.instance!;

  static Future<void> initialize() async {
    final completer = Completer<void>();

    _workerIsolate = await Isolate.spawn(_downloadIsolateEntry, (
      _mainReceivePort.sendPort,
      _rootToken,
    ));

    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        _workerSendPort = message;
        completer.complete();
      }
    });

    return completer.future;
  }

  static void addTask(ComicDownloadTask task) {
    _workerSendPort.send(task);
  }

  static void dispose() {
    _mainReceivePort.close();
    _workerIsolate.kill();
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
