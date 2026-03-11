import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/http.dart' show fetchChapterImagesIsolate;
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'models.dart';

class BackgroundDownloader {
  static ReceivePort? _mainReceivePort;
  static Isolate? _workerIsolate;
  static SendPort? _workerSendPort;
  static Future<void>? _initializeFuture;
  static final RootIsolateToken _rootToken = RootIsolateToken.instance!;

  static StreamController<List<ComicDownloadTask>>? _tasksController;
  static StreamController<int>? _speedController;

  static StreamController<List<ComicDownloadTask>> get streamController {
    return _tasksController ??=
        StreamController<List<ComicDownloadTask>>.broadcast();
  }

  static StreamController<int> get speedStreamController {
    return _speedController ??= StreamController<int>.broadcast();
  }

  static Future<void> initialize() {
    return _initializeFuture ??= _doInitialize();
  }

  static Future<void> _doInitialize() async {
    final receivePort = ReceivePort();
    final readyCompleter = Completer<void>();

    _mainReceivePort = receivePort;
    _workerIsolate = await Isolate.spawn(_downloadIsolateEntry, (
      receivePort.sendPort,
      _rootToken,
    ));

    receivePort.listen((message) {
      switch (message) {
        case SendPort sendPort:
          _workerSendPort = sendPort;
          if (!readyCompleter.isCompleted) {
            readyCompleter.complete();
          }
        case List<ComicDownloadTask> tasks:
          streamController.add(List<ComicDownloadTask>.unmodifiable(tasks));
        case DownloadSpeed speed:
          speedStreamController.add(speed.bytesPerSecond);
        case IsolateLogMessage logMessage:
          Log.e(
            logMessage.message,
            error: logMessage.error,
            stackTrace: logMessage.stackTrace == null
                ? null
                : StackTrace.fromString(logMessage.stackTrace!),
          );
      }
    });

    await readyCompleter.future;
  }

  static void getTasks() {
    _postMessage(const WorkerMessage(type: WorkerMessageType.query));
  }

  static void addTask(ComicDownloadTask task) {
    _postMessage(task);
  }

  static void pauseTask(String taskId) {
    _postMessage(WorkerMessage(type: WorkerMessageType.pause, payload: taskId));
  }

  static void resumeTask(String taskId) {
    _postMessage(
      WorkerMessage(type: WorkerMessageType.resume, payload: taskId),
    );
  }

  static void deleteTasks(List<String> taskIds) {
    _postMessage(
      WorkerMessage(type: WorkerMessageType.delete, payload: taskIds),
    );
  }

  static void dispose() {
    _mainReceivePort?.close();
    _mainReceivePort = null;
    _workerSendPort = null;

    try {
      _workerIsolate?.kill(priority: Isolate.immediate);
    } catch (_) {}
    _workerIsolate = null;

    _tasksController?.close();
    _tasksController = null;
    _speedController?.close();
    _speedController = null;
    _initializeFuture = null;
  }

  static void _postMessage(dynamic message) {
    unawaited(
      initialize()
          .then((_) {
            final sendPort = _workerSendPort;
            if (sendPort == null) {
              Log.w('BackgroundDownloader worker is not ready');
              return;
            }
            sendPort.send(message);
          })
          .catchError((Object error, StackTrace stackTrace) {
            Log.e(
              'BackgroundDownloader post message failed',
              error: error,
              stackTrace: stackTrace,
            );
          }),
    );
  }
}

void _downloadIsolateEntry((SendPort, RootIsolateToken) args) async {
  final (sendPort, rootToken) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final receivePort = ReceivePort();
  final worker = _DownloadWorker(mainSendPort: sendPort);

  sendPort.send(receivePort.sendPort);

  await worker.initialize();

  receivePort.listen(worker.handleMessage);
}

class _DownloadWorker {
  _DownloadWorker({required SendPort mainSendPort})
    : _mainSendPort = mainSendPort;

  static const int _defaultConcurrency = 3;
  static const int _chapterInitConcurrency = 2;
  static const int _maxRetryCount = 3;

  final SendPort _mainSendPort;
  final DownloadTaskHelper _taskHelper = DownloadTaskHelper();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  final List<ComicDownloadTask> _tasks = <ComicDownloadTask>[];
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};
  final Map<String, int> _taskSessionIds = <String, int>{};

  late final _TaskPersistenceCoordinator _persistence;
  late final _SpeedReporter _speedReporter;
  late final String _downloadRootPath;

  Future<void> _mutationQueue = Future.value();
  bool _isQueueLoopRunning = false;

  Future<void> initialize() async {
    _downloadRootPath = await getDownloadDirectory();
    await _taskHelper.initialize();

    _persistence = _TaskPersistenceCoordinator(
      helper: _taskHelper,
      onError: _sendLogError,
    );
    _speedReporter = _SpeedReporter(
      onTick: (bytesPerSecond) {
        _mainSendPort.send(DownloadSpeed(bytesPerSecond: bytesPerSecond));
      },
    );

    final restoredTasks = await _taskHelper.getAll();
    _tasks.addAll(restoredTasks);

    for (final task in _tasks) {
      _cancelTokens[task.comic.id] = CancelToken();
    }

    final normalizedTasks = _normalizeRestoredTasks();
    for (final task in normalizedTasks) {
      await _persistence.flushTaskProgress(task);
    }

    _publishTasks();
    _triggerQueueProcessing();
  }

  void handleMessage(dynamic message) {
    if (message is ComicDownloadTask) {
      _enqueueMutation(() => _handleAddTask(message));
      return;
    }

    if (message is WorkerMessage) {
      _enqueueMutation(() => _handleWorkerMessage(message));
    }
  }

  void _enqueueMutation(Future<void> Function() action) {
    _mutationQueue = _mutationQueue.then((_) => action()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _sendLogError(
        'download worker mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  List<ComicDownloadTask> _normalizeRestoredTasks() {
    var hasDownloadingTask = false;
    final normalizedTasks = <ComicDownloadTask>[];

    for (final task in _tasks) {
      _sortChapters(task);

      if (task.status == DownloadTaskStatus.downloading) {
        if (hasDownloadingTask) {
          task.status = DownloadTaskStatus.queued;
          normalizedTasks.add(task);
        } else {
          hasDownloadingTask = true;
        }
      }
    }

    return normalizedTasks;
  }

  Future<void> _handleAddTask(ComicDownloadTask incomingTask) async {
    _sortChapters(incomingTask);

    final existingTask = _findTask(incomingTask.comic.id);
    final currentDownloadingTask = _findDownloadingTask();

    if (existingTask != null) {
      final existingChapterIds = existingTask.chapters.map((e) => e.id).toSet();
      final newChapters = incomingTask.chapters
          .where((chapter) => !existingChapterIds.contains(chapter.id))
          .toList();

      if (newChapters.isEmpty) {
        _publishTasks();
        return;
      }

      existingTask.chapters.addAll(newChapters);
      _sortChapters(existingTask);

      if (currentDownloadingTask == null ||
          currentDownloadingTask.comic.id == existingTask.comic.id) {
        _cancelTaskExecution(existingTask.comic.id);
        existingTask.status = DownloadTaskStatus.downloading;
      } else {
        existingTask.status = DownloadTaskStatus.queued;
      }

      await _persistence.persistTaskStructure(existingTask);
      _publishTasks();
      _triggerQueueProcessing();
      return;
    }

    incomingTask.status = currentDownloadingTask == null
        ? DownloadTaskStatus.downloading
        : DownloadTaskStatus.queued;

    _cancelTokens[incomingTask.comic.id] = CancelToken();
    _tasks.add(incomingTask);

    await _persistence.persistTaskStructure(incomingTask);
    _publishTasks();
    _triggerQueueProcessing();
  }

  Future<void> _handleWorkerMessage(WorkerMessage message) async {
    switch (message.type) {
      case WorkerMessageType.query:
        _publishTasks();
        return;
      case WorkerMessageType.pause:
        await _pauseTask(message.payload as String);
        return;
      case WorkerMessageType.resume:
        await _resumeTask(message.payload as String);
        return;
      case WorkerMessageType.delete:
        await _deleteTasks(List<String>.from(message.payload as List));
        return;
    }
  }

  Future<void> _pauseTask(String taskId) async {
    final task = _findTask(taskId);
    if (task == null || task.status == DownloadTaskStatus.completed) {
      return;
    }

    _cancelTaskExecution(taskId);
    task.status = DownloadTaskStatus.paused;

    await _persistence.flushTaskProgress(task);
    _publishTasks();
    _triggerQueueProcessing();
  }

  Future<void> _resumeTask(String taskId) async {
    final targetTask = _findTask(taskId);
    if (targetTask == null ||
        targetTask.status == DownloadTaskStatus.completed) {
      return;
    }

    final currentDownloadingTask = _findDownloadingTask();
    if (currentDownloadingTask != null &&
        currentDownloadingTask.comic.id != targetTask.comic.id) {
      _cancelTaskExecution(currentDownloadingTask.comic.id);
      currentDownloadingTask.status = DownloadTaskStatus.paused;
      await _persistence.flushTaskProgress(currentDownloadingTask);
    }

    targetTask.status = DownloadTaskStatus.downloading;

    await _persistence.flushTaskProgress(targetTask);
    _publishTasks();
    _triggerQueueProcessing();
  }

  Future<void> _deleteTasks(List<String> taskIds) async {
    final uniqueTaskIds = taskIds.toSet().toList();
    if (uniqueTaskIds.isEmpty) {
      return;
    }

    final deletingTasks = <ComicDownloadTask>[];
    for (final taskId in uniqueTaskIds) {
      final task = _findTask(taskId);
      if (task == null) {
        continue;
      }

      _cancelTaskExecution(taskId);
      _cancelTokens.remove(taskId);
      deletingTasks.add(task);
    }

    _tasks.removeWhere((task) => uniqueTaskIds.contains(task.comic.id));
    await _persistence.deleteTasks(uniqueTaskIds);
    _publishTasks();

    for (final task in deletingTasks) {
      unawaited(_deleteTaskFolder(task));
    }

    _triggerQueueProcessing();
  }

  void _triggerQueueProcessing() {
    if (_isQueueLoopRunning) {
      return;
    }

    unawaited(_runQueueLoop());
  }

  Future<void> _runQueueLoop() async {
    if (_isQueueLoopRunning) {
      return;
    }

    _isQueueLoopRunning = true;
    try {
      while (true) {
        final task = _nextRunnableTask();
        if (task == null) {
          return;
        }

        if (task.status == DownloadTaskStatus.queued) {
          task.status = DownloadTaskStatus.downloading;
          await _persistence.flushTaskProgress(task);
          _publishTasks();
        }

        await _runTask(task);
      }
    } finally {
      _isQueueLoopRunning = false;

      if (_nextRunnableTask() != null) {
        _triggerQueueProcessing();
      }
    }
  }

  ComicDownloadTask? _nextRunnableTask() {
    final downloadingTask = _findDownloadingTask();
    if (downloadingTask != null) {
      return downloadingTask;
    }

    return _tasks.firstWhereOrNull(
      (task) => task.status == DownloadTaskStatus.queued,
    );
  }

  ComicDownloadTask? _findDownloadingTask() {
    return _tasks.firstWhereOrNull(
      (task) => task.status == DownloadTaskStatus.downloading,
    );
  }

  ComicDownloadTask? _findTask(String taskId) {
    return _tasks.firstWhereOrNull((task) => task.comic.id == taskId);
  }

  Future<void> _runTask(ComicDownloadTask task) async {
    final taskId = task.comic.id;
    final sessionId = _openTaskSession(taskId);
    final cancelToken = _replaceCancelToken(taskId);

    try {
      await _prepareTask(task, sessionId);
      if (!_canContinueTask(taskId, sessionId)) {
        return;
      }

      final api = await _loadApi();
      final plan = _buildDownloadPlan(task, api);
      final missingJobs = _reconcileTaskProgress(task, plan);

      if (!_canContinueTask(taskId, sessionId)) {
        return;
      }

      if (task.total == 0 || task.completed >= task.total) {
        task.status = DownloadTaskStatus.completed;
        await _persistence.flushTaskProgress(task);
        _publishTasks();
        return;
      }

      await _createTargetDirectories(missingJobs);
      await _downloadMissingJobs(
        task: task,
        jobs: missingJobs,
        cancelToken: cancelToken,
        sessionId: sessionId,
      );

      if (!_canContinueTask(taskId, sessionId)) {
        return;
      }

      if (task.total == 0 || task.completed >= task.total) {
        task.status = DownloadTaskStatus.completed;
        await _persistence.flushTaskProgress(task);
        _publishTasks();
      }
    } on DioException catch (error, stackTrace) {
      if (error.type == DioExceptionType.cancel) {
        return;
      }

      await _markTaskAsError(task, error, stackTrace, sessionId);
    } catch (error, stackTrace) {
      await _markTaskAsError(task, error, stackTrace, sessionId);
    }
  }

  Future<void> _prepareTask(ComicDownloadTask task, int sessionId) async {
    _sortChapters(task);

    final chaptersToInitialize = task.chapters
        .where((chapter) => chapter.images.isEmpty)
        .toList();

    if (chaptersToInitialize.isNotEmpty) {
      final token = await _prefs.getString('token') ?? '';
      final api = await _loadApi();
      final pool = Pool(_chapterInitConcurrency);

      try {
        await Future.wait(
          chaptersToInitialize.map((chapter) {
            return pool.withResource(() async {
              if (!_canContinueTask(task.comic.id, sessionId)) {
                return;
              }

              final images = await _fetchChapterImagesWithRetry(
                payload: FetchChapterImagesPayload(
                  id: task.comic.id,
                  order: chapter.order,
                ),
                token: token,
                host: api.host,
              );

              if (!_canContinueTask(task.comic.id, sessionId)) {
                return;
              }

              chapter.images
                ..clear()
                ..addAll(images.map((item) => item.media));
            });
          }),
          eagerError: true,
        );
      } finally {
        await pool.close();
      }
    }

    final totalImages = _countTaskImages(task);
    final shouldPersistStructure =
        task.total != totalImages ||
        chaptersToInitialize.isNotEmpty ||
        task.completed > totalImages;

    task.total = totalImages;
    if (task.completed > task.total) {
      task.completed = task.total;
    }

    if (shouldPersistStructure) {
      await _persistence.persistTaskStructure(task);
      _publishTasks();
    }
  }

  Future<List<ChapterImage>> _fetchChapterImagesWithRetry({
    required FetchChapterImagesPayload payload,
    required String token,
    required String host,
  }) async {
    return _retry<List<ChapterImage>>(
      maxAttempts: _maxRetryCount,
      run: (_) => fetchChapterImagesIsolate(payload, token, host),
    );
  }

  Future<void> _markTaskAsError(
    ComicDownloadTask task,
    Object error,
    StackTrace stackTrace,
    int sessionId,
  ) async {
    if (!_canContinueTask(task.comic.id, sessionId)) {
      return;
    }

    task.status = DownloadTaskStatus.error;
    await _persistence.flushTaskProgress(task);
    _publishTasks();

    _sendLogError(
      'download task failed (${task.comic.id})',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _downloadMissingJobs({
    required ComicDownloadTask task,
    required List<_DownloadJob> jobs,
    required CancelToken cancelToken,
    required int sessionId,
  }) async {
    if (jobs.isEmpty) {
      return;
    }

    Object? failureError;
    StackTrace? failureStackTrace;
    final pool = Pool(_defaultConcurrency);

    try {
      await Future.wait(
        jobs.map((job) {
          return pool.withResource(() async {
            if (cancelToken.isCancelled ||
                !_canContinueTask(task.comic.id, sessionId)) {
              return;
            }

            try {
              await _downloadSingleImage(
                url: job.url,
                path: job.filePath,
                cancelToken: cancelToken,
              );
            } catch (error, stackTrace) {
              final isCancelled =
                  error is DioException &&
                  error.type == DioExceptionType.cancel;
              if (!isCancelled) {
                failureError ??= error;
                failureStackTrace ??= stackTrace;
                if (!cancelToken.isCancelled) {
                  cancelToken.cancel('download task failed');
                }
              }
              Error.throwWithStackTrace(error, stackTrace);
            }

            if (!_canContinueTask(task.comic.id, sessionId)) {
              return;
            }

            task.completed += 1;
            _publishTasks();
            _persistence.scheduleTaskProgress(task);
          });
        }),
        eagerError: true,
      );

      await _persistence.flushTaskProgress(task);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel && failureError != null) {
        Error.throwWithStackTrace(failureError!, failureStackTrace!);
      }
      rethrow;
    } catch (error, stackTrace) {
      if (failureError != null && !identical(error, failureError)) {
        Error.throwWithStackTrace(failureError!, failureStackTrace!);
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await pool.close();
    }
  }

  Future<void> _downloadSingleImage({
    required String url,
    required String path,
    required CancelToken cancelToken,
  }) async {
    final targetFile = File(path);
    if (_isFileReady(targetFile)) {
      return;
    }

    final tempFile = File('$path.part');

    await _retry<void>(
      maxAttempts: _maxRetryCount,
      run: (_) async {
        await _safeDeleteFile(tempFile);

        var previousCount = 0;
        await _dio.download(
          url,
          tempFile.path,
          cancelToken: cancelToken,
          onReceiveProgress: (count, _) {
            _speedReporter.addBytes(count - previousCount);
            previousCount = count;
          },
        );

        if (!await tempFile.exists()) {
          throw StateError(
            'Temporary file missing after download: ${tempFile.path}',
          );
        }

        if (await targetFile.exists()) {
          await _safeDeleteFile(targetFile);
        }

        await tempFile.rename(targetFile.path);
      },
      onRetry: (_, _, _) async {
        await _safeDeleteFile(tempFile);
      },
    );
  }

  Future<void> _createTargetDirectories(List<_DownloadJob> jobs) async {
    final directories = jobs.map((job) => job.directoryPath).toSet();
    for (final directoryPath in directories) {
      await Directory(directoryPath).create(recursive: true);
    }
  }

  List<_DownloadJob> _buildDownloadPlan(ComicDownloadTask task, Api api) {
    final plan = <_DownloadJob>[];
    final orderedChapters = [...task.chapters]..sort(_compareChapter);

    for (final chapter in orderedChapters) {
      final chapterDirectory = p.join(
        _downloadRootPath,
        task.comic.title.legalized,
        '${chapter.order}_${chapter.title.legalized}',
      );

      for (var index = 0; index < chapter.images.length; index++) {
        final image = chapter.images[index];
        final ext = p.extension(image.originalName).isEmpty
            ? '.jpg'
            : p.extension(image.originalName);
        final fileName = '${(index + 1).toString().padLeft(4, '0')}$ext';

        plan.add(
          _DownloadJob(
            url: image.getIsolateDownloadUrl(api),
            filePath: p.join(chapterDirectory, fileName),
          ),
        );
      }
    }

    return plan;
  }

  List<_DownloadJob> _reconcileTaskProgress(
    ComicDownloadTask task,
    List<_DownloadJob> plan,
  ) {
    final missingJobs = <_DownloadJob>[];
    var completed = 0;

    for (final job in plan) {
      if (_isFileReady(File(job.filePath))) {
        completed += 1;
      } else {
        missingJobs.add(job);
      }
    }

    final progressChanged =
        task.total != plan.length || task.completed != completed;
    task.total = plan.length;
    task.completed = completed;

    if (progressChanged) {
      _publishTasks();
      _persistence.scheduleTaskProgress(task);
    }

    return missingJobs;
  }

  bool _isFileReady(File file) {
    if (!file.existsSync()) {
      return false;
    }

    try {
      final length = file.lengthSync();
      if (length > 0) {
        return true;
      }

      file.deleteSync();
    } catch (_) {}

    return false;
  }

  Future<void> _safeDeleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _deleteTaskFolder(ComicDownloadTask task) async {
    final folder = Directory(
      p.join(_downloadRootPath, task.comic.title.legalized),
    );

    if (!await folder.exists()) {
      return;
    }

    try {
      await folder.delete(recursive: true);
    } catch (error, stackTrace) {
      _sendLogError(
        'delete download folder failed (${folder.path})',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  int _countTaskImages(ComicDownloadTask task) {
    return task.chapters.fold<int>(
      0,
      (sum, chapter) => sum + chapter.images.length,
    );
  }

  void _sortChapters(ComicDownloadTask task) {
    task.chapters.sort(_compareChapter);
  }

  int _compareChapter(DownloadChapter a, DownloadChapter b) {
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.id.compareTo(b.id);
  }

  Future<Api> _loadApi() async {
    return Api.fromName(await _prefs.getString('api'));
  }

  int _openTaskSession(String taskId) {
    final nextSessionId = (_taskSessionIds[taskId] ?? 0) + 1;
    _taskSessionIds[taskId] = nextSessionId;
    return nextSessionId;
  }

  CancelToken _replaceCancelToken(String taskId) {
    _cancelTokens[taskId]?.cancel();
    final token = CancelToken();
    _cancelTokens[taskId] = token;
    return token;
  }

  void _cancelTaskExecution(String taskId) {
    _taskSessionIds[taskId] = (_taskSessionIds[taskId] ?? 0) + 1;
    _cancelTokens[taskId]?.cancel();
    _cancelTokens[taskId] = CancelToken();
  }

  bool _canContinueTask(String taskId, int sessionId) {
    final task = _findTask(taskId);
    return task != null &&
        task.status == DownloadTaskStatus.downloading &&
        _taskSessionIds[taskId] == sessionId;
  }

  void _publishTasks() {
    _mainSendPort.send(List<ComicDownloadTask>.from(_tasks));
  }

  void _sendLogError(String message, {Object? error, StackTrace? stackTrace}) {
    _mainSendPort.send(
      IsolateLogMessage(
        message: message,
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
      ),
    );
  }

  Future<T> _retry<T>({
    required Future<T> Function(int attempt) run,
    required int maxAttempts,
    FutureOr<void> Function(int attempt, Object error, StackTrace stackTrace)?
    onRetry,
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await run(attempt);
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        final isCancelled =
            error is DioException && error.type == DioExceptionType.cancel;
        if (attempt == maxAttempts - 1 || isCancelled) {
          rethrow;
        }

        await onRetry?.call(attempt, error, stackTrace);
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }
}

class _TaskPersistenceCoordinator {
  _TaskPersistenceCoordinator({required this.helper, required this.onError});

  final DownloadTaskHelper helper;
  final void Function(String message, {Object? error, StackTrace? stackTrace})
  onError;

  final Map<String, Timer> _progressTimers = <String, Timer>{};

  Future<void> persistTaskStructure(ComicDownloadTask task) async {
    _cancelProgressTimer(task.comic.id);
    await _guard(
      'persist task structure (${task.comic.id})',
      () => helper.insertSingleTask(task),
    );
  }

  void scheduleTaskProgress(ComicDownloadTask task) {
    _cancelProgressTimer(task.comic.id);

    _progressTimers[task.comic.id] = Timer(
      const Duration(milliseconds: 500),
      () {
        _progressTimers.remove(task.comic.id);
        unawaited(flushTaskProgress(task));
      },
    );
  }

  Future<void> flushTaskProgress(ComicDownloadTask task) async {
    _cancelProgressTimer(task.comic.id);
    await _guard(
      'flush task progress (${task.comic.id})',
      () => helper.updateTaskProgress(task),
    );
  }

  Future<void> deleteTasks(List<String> taskIds) async {
    for (final taskId in taskIds) {
      _cancelProgressTimer(taskId);
    }

    await _guard('delete task batch', () => helper.deleteBatch(taskIds));
  }

  void _cancelProgressTimer(String taskId) {
    _progressTimers.remove(taskId)?.cancel();
  }

  Future<void> _guard(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      onError(label, error: error, stackTrace: stackTrace);
    }
  }
}

class _SpeedReporter {
  _SpeedReporter({required this.onTick}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentBytes = _bytesInWindow;
      _bytesInWindow = 0;

      if (currentBytes > 0 || _lastSentBytes > 0) {
        onTick(currentBytes);
        _lastSentBytes = currentBytes;
      }
    });
  }

  final void Function(int bytesPerSecond) onTick;

  late final Timer _timer;
  int _bytesInWindow = 0;
  int _lastSentBytes = 0;

  void addBytes(int bytes) {
    if (bytes <= 0) {
      return;
    }

    _bytesInWindow += bytes;
  }

  void dispose() {
    _timer.cancel();
  }
}

class _DownloadJob {
  const _DownloadJob({required this.url, required this.filePath});

  final String url;
  final String filePath;

  String get directoryPath => p.dirname(filePath);
}
