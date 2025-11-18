import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:legalize/legalize.dart';
import 'package:path/path.dart' as p;
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
enum _CommandType { pause, resume, delete, query }

/// 下载命令
class _DownloadCommand {
  final dynamic params;
  final _CommandType type;

  const _DownloadCommand({required this.params, required this.type});
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
    final path = await getDownloadDirectory();
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
        update(task);
      }
    }
  }

  /// 保存缓存
  static Future<void> setCache([ComicDownloadTask? task]) async {
    final downloadTaskHelper = DownloadTaskHelper();
    if (task != null) {
      await downloadTaskHelper.insertSingleTask(task);
    } else {
      await downloadTaskHelper.insert(tasks);
    }
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

  /// 下载
  static Future<void> download(ComicDownloadTask task) async {
    final remaining = <MapEntry<DownloadChapter, ImageDetail>>[];
    int i = 0;
    for (final chapter in task.chapters) {
      for (final image in chapter.images) {
        if (i++ < task.completed) continue;
        remaining.add(MapEntry(chapter, image));
      }
    }

    const batchSize = 3;
    final api = Api.fromName(
      (await SharedPreferences.getInstance()).getString('api'),
    );

    for (int start = 0; start < remaining.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, remaining.length);
      final batch = remaining.sublist(start, end);

      final futures = <Future>[];

      for (final entry in batch) {
        final chapter = entry.key;
        final image = entry.value;

        final path = p.join(
          _dirPath,
          legalizeFilename(task.comic.title, os: Platform.operatingSystem),
          legalizeFilename(chapter.title, os: Platform.operatingSystem),
          image.originalName,
        );

        futures.add(
          _downloadImage(
            image.getIsolateDownloadUrl(api),
            path,
            _cancelTokens[task.comic.id],
          ).then((_) {
            task.completed++;
            if (task.completed >= task.total) {
              task.status = DownloadTaskStatus.completed;
              startNextTask();
            }

            notify(task: task);
          }),
        );
      }

      try {
        await Future.wait(futures);
      } catch (error) {
        debugPrint('Error downloading image: $error');

        // 检查是否为取消导致的错误
        final isCancelled =
            error is DioException && error.type == DioExceptionType.cancel;
        if (isCancelled) {
          return;
        }

        _cancelTokens[task.comic.id]?.cancel();
        _cancelTokens[task.comic.id] = CancelToken();
        task.status = DownloadTaskStatus.error;
        startNextTask();
        notify(task: task);
        return;
      }
    }
  }

  static Future<List<ChapterImage>> _fetchChapterImagesIsolate(
    FetchChapterImagesPayload payload,
    String token,
    String host,
  ) async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await fetchChapterImagesIsolate(payload, token, host);
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
    final api = Api.fromName(prefs.getString('api'));

    if (token == null) {
      throw Exception('Token is null');
    }

    final response = await _fetchChapterImagesIsolate(
      FetchChapterImagesPayload(id: id, order: chapter.order),
      token,
      api.host,
    );
    chapter.images.addAll(response.map((e) => e.media));
  }

  /// 开启下一个排队任务
  static Future<void> startNextTask() async {
    final nextTask = tasks.firstWhereOrNull(
      (t) => t.status == DownloadTaskStatus.queued,
    );
    if (nextTask != null) {
      nextTask.status = DownloadTaskStatus.downloading;
      update(nextTask);
    }
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
      notify(task: task);
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
        task.status = DownloadTaskStatus.queued;
      }
      _cancelTokens[task.comic.id] = CancelToken();
      tasks.add(task);
    }
    notify(task: task);
  }

  /// 暂停下载任务
  static void pause(String comicId) {
    _cancelTokens[comicId]?.cancel();
    _cancelTokens[comicId] = CancelToken();
    final index = tasks.indexWhere((t) => comicId == t.comic.id);
    if (index != -1) {
      tasks[index].status = DownloadTaskStatus.paused;
      startNextTask();
      notify(task: tasks[index]);
    }
  }

  /// 恢复下载任务
  static void resume(String comicId) {
    // 如果有，暂停当前正在下载的任务
    final downloadingTask = tasks.firstWhereOrNull(
      (t) => t.status == DownloadTaskStatus.downloading,
    );
    if (downloadingTask != null) {
      downloadingTask.status = DownloadTaskStatus.paused;
      _cancelTokens[downloadingTask.comic.id]?.cancel();
      _cancelTokens[downloadingTask.comic.id] = CancelToken();
      setCache(downloadingTask);
    }

    final index = tasks.indexWhere((t) => comicId == t.comic.id);
    if (index != -1) {
      tasks[index].status = DownloadTaskStatus.downloading;
      update(tasks[index]);
      notify(task: tasks[index]);
    }
  }

  /// 删除下载任务
  static void delete(List<String> taskIds) {
    for (var id in taskIds) {
      _cancelTokens[id]?.cancel();
      _cancelTokens.remove(id);
      final index = tasks.indexWhere((t) => t.comic.id == id);
      if (index != -1) {
        final path = p.join(
          _dirPath,
          legalizeFilename(
            tasks[index].comic.title,
            os: Platform.operatingSystem,
          ),
        );
        if (Directory(path).existsSync()) {
          Directory(path).deleteSync(recursive: true);
        }
        tasks.removeAt(index);
      }
    }
    final downloadTaskHelper = DownloadTaskHelper();
    downloadTaskHelper.deleteBatch(taskIds);
    notify(cache: false);
  }

  /// 发送，缓存最新下载任务列表
  static void notify({bool cache = true, ComicDownloadTask? task}) {
    mainIsolateSendPort.send(tasks);
    if (cache) {
      setCache(task);
    }
  }

  /// 处理下载命令
  static void handleCommand(_DownloadCommand command) {
    switch (command.type) {
      case _CommandType.query:
        notify(cache: false);
        break;
      case _CommandType.pause:
        pause(command.params);
        break;
      case _CommandType.resume:
        resume(command.params);
        break;
      case _CommandType.delete:
        delete(command.params);
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
      switch (message) {
        case SendPort sendPort:
          _workerSendPort = sendPort;
          completer.complete();
        case List<ComicDownloadTask> tasks:
          streamController.add(tasks);
      }
    });

    return completer.future;
  }

  // 查询下载任务
  static void getTasks() => _workerSendPort.send(
    const _DownloadCommand(type: _CommandType.query, params: null),
  );

  /// 添加下载任务
  static void addTask(ComicDownloadTask task) {
    _workerSendPort.send(task);
  }

  /// 暂停下载任务
  static void pauseTask(String taskId) {
    _workerSendPort.send(
      _DownloadCommand(params: taskId, type: _CommandType.pause),
    );
  }

  /// 恢复下载任务
  static void resumeTask(String taskId) {
    _workerSendPort.send(
      _DownloadCommand(params: taskId, type: _CommandType.resume),
    );
  }

  /// 取消下载任务
  static void deleteTasks(List<String> taskIds) {
    _workerSendPort.send(
      _DownloadCommand(params: taskIds, type: _CommandType.delete),
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
  error;

  const DownloadTaskStatus();

  static DownloadTaskStatus fromName(String name) {
    return DownloadTaskStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw Exception('Unknown status name: $name'),
    );
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
