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

/// 下载隔离区入口点
void _downloadIsolateEntry((SendPort, RootIsolateToken) args) {
  final (sendPort, rootToken) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  _ComicDownloader.mainIsolateSendPort = sendPort;

  receivePort.listen((message) {
    if (message is ComicDownloadTask) {
      _ComicDownloader.add(message);
    } else if (message is _DownloadCommand) {
      _ComicDownloader.handleCommand(message);
    }
  });
}

/// 下载命令类型
enum _CommandType { pause, resume, cancel, query }

/// 下载命令
class _DownloadCommand {
  final String comicId;
  final _CommandType type;

  const _DownloadCommand({required this.comicId, required this.type});
}

/// 漫画下载器
class _ComicDownloader {
  static final List<ComicDownloadTask> tasks = [];
  static final Dio dio = Dio();
  static final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};
  static late final SendPort mainIsolateSendPort;

  /// 下载单张图片
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

  /// 下载任务
  static Future<void> download(ComicDownloadTask task) async {
    final dirPath = (await getApplicationDocumentsDirectory()).path;
    int i = 0;

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

        notify();
      }
    }
  }

  /// 初始化章节数据
  static Future<void> chapterInitialize(
    DownloadChapter chapter,
    String id,
  ) async {
    if (chapter.images.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token is null');
    }

    final response = await fetchChapterImagesIsolate(
      FetchChapterImagesPayload(id: id, order: chapter.order),
      token,
    );
    chapter.images.addAll(response.map((e) => e.media));
  }

  /// 更新任务
  static Future<void> update(ComicDownloadTask task) async {
    task.total = 0;
    for (var chapter in task.chapters) {
      await chapterInitialize(chapter, task.comic.id);
      task.total += chapter.images.length;
    }
    download(task);
  }

  /// 添加下载任务
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

  /// 暂停下载任务
  static void pause(String comicId) {
    _cancelTokens[comicId]?.cancel();
    _cancelTokens[comicId] = CancelToken();
  }

  /// 查询下载任务
  static void notify() => mainIsolateSendPort.send(tasks);

  /// 处理下载命令
  static void handleCommand(_DownloadCommand command) {
    switch (command.type) {
      case _CommandType.query:
        notify();
        break;
      case _CommandType.pause:
        pause(command.comicId);
        break;
      case _CommandType.resume:
        final index = tasks.indexWhere((t) => command.comicId == t.comic.id);
        if (index != -1) {
          update(tasks[index]);
        }
        break;
      case _CommandType.cancel:
        pause(command.comicId);
        tasks.removeWhere((t) => t.comic.id == command.comicId);
        break;
    }
  }
}

/// 下载管理器
class DownloadManager {
  static final ReceivePort _mainReceivePort = ReceivePort();
  static late final Isolate _workerIsolate;
  static late final SendPort _workerSendPort;
  static final _rootToken = RootIsolateToken.instance!;
  static final streamController =
      StreamController<List<ComicDownloadTask>>.broadcast();

  /// 初始化下载管理器
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
      } else if (message is List<ComicDownloadTask>) {
        streamController.add(message);
      }
    });

    return completer.future;
  }

  // 查询下载任务
  static void getTasks() => _workerSendPort.send(
    const _DownloadCommand(type: _CommandType.query, comicId: ''),
  );

  /// 添加下载任务
  static void addTask(ComicDownloadTask task) {
    _workerSendPort.send(task);
  }

  /// 暂停下载任务
  static void pauseTask(String comicId) {
    _workerSendPort.send(
      _DownloadCommand(comicId: comicId, type: _CommandType.pause),
    );
  }

  /// 恢复下载任务
  static void resumeTask(String comicId) {
    _workerSendPort.send(
      _DownloadCommand(comicId: comicId, type: _CommandType.resume),
    );
  }

  /// 取消下载任务
  static void cancelTask(String comicId) {
    _workerSendPort.send(
      _DownloadCommand(comicId: comicId, type: _CommandType.cancel),
    );
  }

  /// 释放资源
  static void dispose() {
    _mainReceivePort.close();
    _workerIsolate.kill();
    streamController.close();
  }
}

/// 漫画下载任务
class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;

  int total = 0;
  int completed = 0;

  ComicDownloadTask({required this.comic, required this.chapters});
}

/// 下载章节
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

/// 下载漫画
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
