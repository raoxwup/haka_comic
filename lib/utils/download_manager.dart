import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 下载隔离区入口点
void _downloadIsolateEntry((SendPort, RootIsolateToken) args) async {
  final (sendPort, rootToken) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  _ComicDownloader.mainIsolateSendPort = sendPort;

  await _ComicDownloader.initialize();

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
  static late final String _dirPath;

  static Future<void> initialize() async {
    await initializeDownloadDirectory();
    await readCache();
  }

  /// 初始化下载目录
  static Future<void> initializeDownloadDirectory() async {
    String path;
    if (isIos) {
      path = (await getApplicationDocumentsDirectory()).path;
    } else {
      final downloadPath = (await getDownloadsDirectory())?.path;
      if (downloadPath == null) {
        if (isAndroid) {
          final externalPath = (await getExternalStorageDirectory())?.path;
          if (externalPath == null) {
            path = (await getApplicationDocumentsDirectory()).path;
          } else {
            path = externalPath;
          }
        } else {
          path = (await getApplicationDocumentsDirectory()).path;
        }
      } else {
        path = downloadPath;
      }
    }
    _dirPath = path;
  }

  /// 读取缓存
  static Future<void> readCache() async {
    final downloadTaskHelper = DownloadTaskHelper();
    await downloadTaskHelper.initialize();

    final allTask = await downloadTaskHelper.getAll();
    tasks.addAll(allTask);

    /// 找出正在下载的任务启动
    for (var task in tasks) {
      _cancelTokens[task.comic.id] = CancelToken();
      if (task.status == DownloadTaskStatus.downloading) {
        download(task);
      }
    }
  }

  /// 保存缓存
  static Future<void> setCache() async {
    final downloadTaskHelper = DownloadTaskHelper();
    await downloadTaskHelper.insert(tasks);
  }

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
    int i = 0;

    for (var chapter in task.chapters) {
      for (var image in chapter.images) {
        if (i++ < task.completed) {
          continue;
        }

        final path = p.join(
          _dirPath,
          sanitizeFileName(task.comic.title),
          sanitizeFileName(chapter.title),
          image.originalName,
        );

        await _downloadImage(image.url, path, _cancelTokens[task.comic.id]);
        task.completed++;

        if (task.completed >= task.total) {
          task.status = DownloadTaskStatus.completed;
          // 开启下一个排队中的任务
          final nextTask = tasks.firstWhereOrNull(
            (t) => t.status == DownloadTaskStatus.queued,
          );
          if (nextTask != null) {
            nextTask.status = DownloadTaskStatus.downloading;
            update(nextTask);
          }
        }

        notify();
      }
    }
  }

  static Future<List<ChapterImage>> _fetchChapterImagesIsolate(
    FetchChapterImagesPayload payload,
    String token,
  ) async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await fetchChapterImagesIsolate(payload, token);
        return response;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 2 * i));
      }
    }
    throw Exception(
      'Failed to fetch chapter images after $maxRetries attempts',
    );
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

    final response = await _fetchChapterImagesIsolate(
      FetchChapterImagesPayload(id: id, order: chapter.order),
      token,
    );
    chapter.images.addAll(response.map((e) => e.media));
  }

  /// 更新任务
  static Future<void> update(ComicDownloadTask task) async {
    try {
      task.total = 0;
      for (var chapter in task.chapters) {
        await chapterInitialize(chapter, task.comic.id);
        task.total += chapter.images.length;
      }
      download(task);
    } catch (e) {
      task.status = DownloadTaskStatus.error;
      notify();
    }
  }

  /// 添加下载任务
  static void add(ComicDownloadTask task) {
    // 是否存在正在下载的任务
    final downloadingTask = tasks.firstWhereOrNull(
      (t) => t.status == DownloadTaskStatus.downloading,
    );
    final index = tasks.indexWhere((t) => task.comic.id == t.comic.id);
    if (index != -1) {
      // 已经存在的章节不在添加
      final existingChapters = tasks[index].chapters.map((c) => c.id).toSet();
      task.chapters.removeWhere((c) => existingChapters.contains(c.id));
      // 追加章节
      tasks[index].chapters.addAll(task.chapters);
      if (downloadingTask == null) {
        tasks[index].status = DownloadTaskStatus.downloading;
        update(tasks[index]);
      } else {
        tasks[index].status = DownloadTaskStatus.queued;
      }
    } else {
      if (downloadingTask == null) {
        task.status = DownloadTaskStatus.downloading;
        update(task);
      } else {
        tasks[index].status = DownloadTaskStatus.queued;
      }
      _cancelTokens[task.comic.id] = CancelToken();
      tasks.add(task);
    }
    notify();
  }

  /// 暂停下载任务
  static void pause(String comicId) {
    _cancelTokens[comicId]?.cancel();
    _cancelTokens[comicId] = CancelToken();
    final index = tasks.indexWhere((t) => comicId == t.comic.id);
    if (index != -1) {
      tasks[index].status = DownloadTaskStatus.paused;
      notify();
    }
  }

  /// 发送，缓存最新下载任务列表
  static void notify({bool cache = true}) {
    mainIsolateSendPort.send(tasks);
    if (cache) {
      setCache();
    }
  }

  /// 处理下载命令
  static void handleCommand(_DownloadCommand command) {
    switch (command.type) {
      case _CommandType.query:
        notify(cache: false);
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

/// 下载任务状态
enum DownloadTaskStatus {
  /// 排队中
  queued,

  /// 下载中
  downloading,

  /// 暂停
  paused,

  /// 完成
  completed,

  /// 错误
  error,
}

DownloadTaskStatus downloadTaskStatusFromString(String status) {
  switch (status) {
    case 'queued':
      return DownloadTaskStatus.queued;
    case 'downloading':
      return DownloadTaskStatus.downloading;
    case 'paused':
      return DownloadTaskStatus.paused;
    case 'completed':
      return DownloadTaskStatus.completed;
    case 'error':
      return DownloadTaskStatus.error;
    default:
      throw Exception('Unknown status: $status');
  }
}

/// 漫画下载任务
class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;

  int total = 0;
  int completed = 0;
  DownloadTaskStatus status = DownloadTaskStatus.queued;

  ComicDownloadTask({required this.comic, required this.chapters});
}

/// 下载章节
class DownloadChapter {
  /// 这个章节的所有图片
  final List<ImageDetail> images = [];

  final String id;
  final String title;
  final int order;

  DownloadChapter({required this.id, required this.title, required this.order});
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
