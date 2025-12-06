import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/http.dart' show fetchChapterImagesIsolate;
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

part 'models.dart';

void _downloadIsolateEntry((SendPort, RootIsolateToken) args) async {
  final (sendPort, rootToken) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  _DownloadExecutor.mainIsolateSendPort = sendPort;

  await _DownloadExecutor.initialize();

  receivePort.listen((message) {
    switch (message) {
      case ComicDownloadTask():
        _DownloadExecutor.add(message);
      case WorkerMessage():
        _DownloadExecutor.receive(message);
    }
  });
}

// 下载执行器
class _DownloadExecutor {
  static final List<ComicDownloadTask> tasks = [];
  static final _dio = Dio();
  static final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};
  static late final SendPort mainIsolateSendPort;
  static late final String _downloadPath;
  static final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  /// 默认单任务并发数
  static const int defaultConcurrency = 3;

  static Future<void> initialize() async {
    final path = await getDownloadDirectory();
    _downloadPath = path;

    final downloadTaskHelper = DownloadTaskHelper();
    await downloadTaskHelper.initialize();

    final allTask = await downloadTaskHelper.getAll();
    tasks.addAll(allTask);

    for (var task in tasks) {
      _cancelTokens[task.comic.id] = CancelToken();
      if (task.status == DownloadTaskStatus.downloading) {
        run(task);
      }
    }

    downloadTaskHelper.addListener(notify);
  }

  /// 更新任务（重新计算 total 并开始下载）
  static Future<void> updateTask(
    ComicDownloadTask task, {
    bool runNow = true,
  }) async {
    try {
      task.total = 0;
      for (var chapter in task.chapters) {
        await initializeChapter(chapter, task.comic.id);
        task.total += chapter.images.length;
      }
      save(task);
      if (runNow) {
        await run(task);
      }
    } catch (e, st) {
      task.status = DownloadTaskStatus.error;
      debugPrint('update error for ${task.comic.id}: $e\n$st');
      save(task);
    }
  }

  /// 初始化章节数据（填充 images 列表）
  static Future<void> initializeChapter(
    DownloadChapter chapter,
    String id,
  ) async {
    if (chapter.images.isNotEmpty) return;

    final token = await asyncPrefs.getString('token') ?? '';
    final api = Api.fromName(await asyncPrefs.getString('api'));

    final response = await _fetchChapterImagesIsolate(
      FetchChapterImagesPayload(id: id, order: chapter.order),
      token,
      api.host,
    );
    chapter.images.addAll(response.map((e) => e.media));
  }

  /// 运行一个任务（会等待完成或发生错误）
  static Future<void> run(ComicDownloadTask task) async {
    // 任务已完成
    if (task.total > 0 && task.completed >= task.total) {
      task.status = DownloadTaskStatus.completed;
      save(task);
      startNextTask();
      return;
    }

    final cancelToken = _cancelTokens[task.comic.id] ??= CancelToken();

    final api = Api.fromName(await asyncPrefs.getString('api'));

    // 构建剩余下载列表
    final remaining = <MapEntry<DownloadChapter, (ImageDetail, String)>>[];
    int index = 0;
    for (final chapter in task.chapters) {
      int i = 0;
      for (var image in chapter.images) {
        if (index++ < task.completed) continue;
        final paddedIndex = (i + 1).toString().padLeft(4, '0');
        final ext = p.extension(image.originalName);
        remaining.add(MapEntry(chapter, (image, '$paddedIndex$ext')));
        i++;
      }
    }

    // 并发控制：使用信号量限制并发（每任务 defaultConcurrency）
    final pool = Pool(defaultConcurrency);
    final List<Future<void>> futures = [];

    for (var entry in remaining) {
      if (cancelToken.isCancelled) break;

      final chapter = entry.key;
      final (image, fileName) = entry.value;
      final path = p.join(
        _downloadPath,
        task.comic.title.legalized,
        '${chapter.order}_${chapter.title.legalized}',
        fileName,
      );

      final fut = pool.withResource(() async {
        if (cancelToken.isCancelled) return;

        await _downloadImage(
          image.getIsolateDownloadUrl(api),
          path,
          cancelToken,
        );

        task.completed++;

        if (task.total > 0 && task.completed >= task.total) {
          task.status = DownloadTaskStatus.completed;
          startNextTask();
        }

        save(task);
      });

      futures.add(fut);
    }

    try {
      await Future.wait(futures);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        await pool.close();
        return;
      }

      _cancelTokens[task.comic.id]?.cancel();
      _cancelTokens[task.comic.id] = CancelToken();
      task.status = DownloadTaskStatus.error;
      save(task);

      debugPrint('Download failed for ${task.comic.id}: $e');
    }

    await pool.close();

    // 如果不是错误，检查是否完成
    if (task.total > 0 && task.completed >= task.total) {
      task.status = DownloadTaskStatus.completed;
      save(task);
      startNextTask();
    }
  }

  /// 下载单张图片
  static Future<void> _downloadImage(
    String url,
    String path,
    CancelToken cancelToken,
  ) async {
    const maxRetries = 3;
    final dir = p.dirname(path);
    await Directory(dir).create(recursive: true);

    final target = File(path);
    if (target.existsSync() && target.lengthSync() > 0) {
      return;
    }

    final tmpPath = '$path.part';

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _dio.download(url, tmpPath, cancelToken: cancelToken);
        final tmpFile = File(tmpPath);
        if (tmpFile.existsSync()) {
          if (target.existsSync()) {
            await target.delete();
          }
          await tmpFile.rename(path);
        }
        return;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempt));
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempt));
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
        await Future.delayed(Duration(seconds: 1 << i));
      }
    }
    throw Exception(
      'Failed to fetch chapter images after $maxRetries attempts',
    );
  }

  /// 启动下一个排队任务
  static Future<void> startNextTask() async {
    final nextTask = tasks.firstWhereOrNull(
      (t) => t.status == DownloadTaskStatus.queued,
    );
    if (nextTask != null) {
      nextTask.status = DownloadTaskStatus.downloading;
      save(nextTask);
      run(nextTask);
    }
  }

  /// 通知任务更新
  static void notify() {
    mainIsolateSendPort.send(tasks);
  }

  /// 将任务或全部任务保存到数据库（带 debounce）
  static Future<void> save(ComicDownloadTask task) async {
    final downloadTaskHelper = DownloadTaskHelper();
    try {
      await downloadTaskHelper.insertSingleTask(task);
    } catch (e, st) {
      debugPrint('setCache single task error: $e\n$st');
    }
  }

  /// 添加下载任务（支持追加章节）
  static void add(ComicDownloadTask task) {
    final downloadingTask = tasks.firstWhereOrNull(
      (t) => t.status == DownloadTaskStatus.downloading,
    );
    final index = tasks.indexWhere((t) => task.comic.id == t.comic.id);

    if (index != -1) {
      // 已存在这个漫画的下载任务 合并
      final existingChapters = tasks[index].chapters.map((c) => c.id).toSet();
      final newChapters = task.chapters
          .where((c) => !existingChapters.contains(c.id))
          .toList();
      if (newChapters.isNotEmpty) {
        tasks[index].chapters.addAll(newChapters);
        if (downloadingTask == null) {
          // 如果当前没有下载中的任务，则直接开始
          tasks[index].status = DownloadTaskStatus.downloading;
          updateTask(tasks[index]);
        } else {
          if (downloadingTask.comic.id == tasks[index].comic.id) {
            // 当前下载的漫画跟需要新增的漫画是同一个，需要先暂停，重新获取图片后再开始
            _cancelTokens[downloadingTask.comic.id]?.cancel();
            _cancelTokens[downloadingTask.comic.id] = CancelToken();
            tasks[index].status = DownloadTaskStatus.downloading;
            updateTask(tasks[index]);
            return;
          }
          // 进入排队阶段
          tasks[index].status = DownloadTaskStatus.queued;
          updateTask(tasks[index], runNow: false);
        }
        save(tasks[index]);
      }
    } else {
      // 没有这个漫画的下载任务 新开
      if (downloadingTask == null) {
        task.status = DownloadTaskStatus.downloading;
        updateTask(task);
      } else {
        task.status = DownloadTaskStatus.queued;
        updateTask(task, runNow: false);
      }
      _cancelTokens[task.comic.id] = CancelToken();
      tasks.add(task);
      save(task);
    }
  }

  static void receive(WorkerMessage message) {
    switch (message.type) {
      case WorkerMessageType.query:
        notify();
        break;
      case WorkerMessageType.pause:
        pause(message.payload as String);
        break;
      case WorkerMessageType.resume:
        resume(message.payload as String);
        break;
      case WorkerMessageType.delete:
        delete(List<String>.from(message.payload as List));
        break;
    }
  }

  /// 暂停任务
  static void pause(String comicId) {
    _cancelTokens[comicId]?.cancel();
    _cancelTokens[comicId] = CancelToken();

    final index = tasks.indexWhere((t) => comicId == t.comic.id);
    if (index != -1) {
      tasks[index].status = DownloadTaskStatus.paused;
      startNextTask();
      save(tasks[index]);
    }
  }

  /// 恢复任务（如果有正在下载的任务，会先暂停它）
  static void resume(String comicId) {
    final downloadingTask = tasks.firstWhereOrNull(
      (t) => t.status == DownloadTaskStatus.downloading,
    );
    if (downloadingTask != null) {
      downloadingTask.status = DownloadTaskStatus.paused;
      _cancelTokens[downloadingTask.comic.id]?.cancel();
      _cancelTokens[downloadingTask.comic.id] = CancelToken();
      save(downloadingTask);
    }

    final index = tasks.indexWhere((t) => comicId == t.comic.id);
    if (index != -1) {
      tasks[index].status = DownloadTaskStatus.downloading;
      updateTask(tasks[index]);
      save(tasks[index]);
    }
  }

  /// 删除任务（并删除磁盘文件）
  static void delete(List<String> taskIds) {
    final downloadTaskHelper = DownloadTaskHelper();
    downloadTaskHelper.deleteBatch(taskIds);

    for (var id in taskIds) {
      _cancelTokens[id]?.cancel();
      _cancelTokens.remove(id);

      final index = tasks.indexWhere((t) => t.comic.id == id);
      if (index != -1) {
        final path = p.join(_downloadPath, tasks[index].comic.title.legalized);
        if (Directory(path).existsSync()) {
          try {
            Directory(path).deleteSync(recursive: true);
          } catch (e) {
            debugPrint('Failed to delete folder $path: $e');
          }
        }
        tasks.removeAt(index);
      }
    }

    notify();
  }
}

class BackgroundDownloader {
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

  static void getTasks() => _workerSendPort.send(
    const WorkerMessage(type: WorkerMessageType.query, payload: null),
  );

  /// 添加下载任务
  static void addTask(ComicDownloadTask task) {
    _workerSendPort.send(task);
  }

  /// 暂停下载任务
  static void pauseTask(String taskId) {
    _workerSendPort.send(
      WorkerMessage(payload: taskId, type: WorkerMessageType.pause),
    );
  }

  /// 恢复下载任务
  static void resumeTask(String taskId) {
    _workerSendPort.send(
      WorkerMessage(payload: taskId, type: WorkerMessageType.resume),
    );
  }

  /// 删除下载任务
  static void deleteTasks(List<String> taskIds) {
    _workerSendPort.send(
      WorkerMessage(payload: taskIds, type: WorkerMessageType.delete),
    );
  }

  /// 释放资源
  static void dispose() {
    _mainReceivePort.close();
    try {
      _workerIsolate.kill(priority: Isolate.immediate);
    } catch (_) {}
    streamController.close();
  }
}
