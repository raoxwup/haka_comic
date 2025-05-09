import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:path/path.dart' as p;

class ComicDownloadManager {
  static List<ComicDownloadTask> tasks = [];
  static final StreamController<ComicDownloadTask> _completedController =
      StreamController<ComicDownloadTask>.broadcast();

  /// 下载完成的通知流
  static Stream<ComicDownloadTask> get onTaskCompleted =>
      _completedController.stream;

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

  /// 清理资源
  static void dispose() {
    for (var task in tasks) {
      task.cancel();
    }
    _completedController.close();
  }
}

class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;
  final CancelToken _cancelToken = CancelToken();

  int total = 0;
  int completed = 0;
  bool _isCompleted = false;
  bool _isPaused = false;

  /// 下载进度流
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  /// 下载状态流
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  Isolate? _isolate;
  ReceivePort? _receivePort;

  void update() async {
    _statusController.add('initializing');
    total = 0;
    for (var chapter in chapters) {
      await chapter.initialize(comic.id);
      total += chapter.images.length;
    }
    _startDownloadInBackground();
  }

  void _startDownloadInBackground() async {
    _receivePort = ReceivePort();

    // 准备传递给isolate的数据
    final downloadData = {
      'comic': comic,
      'chapters': chapters,
      'documentsPath': SetupConf.documentsPath,
      'completed': completed,
      'sendPort': _receivePort!.sendPort,
    };

    _isolate = await Isolate.spawn(_downloadIsolate, downloadData);

    _receivePort!.listen((message) {
      if (message is Map) {
        if (message.containsKey('progress')) {
          completed = message['completed'];
          _progressController.add(completed / total);
          _statusController.add('downloading');
        } else if (message.containsKey('completed')) {
          _isCompleted = true;
          _statusController.add('completed');
          _progressController.add(1.0);
          ComicDownloadManager._completedController.add(this);
          _cleanupIsolate();
        } else if (message.containsKey('error')) {
          _statusController.add('error: ${message['error']}');
          _cleanupIsolate();
        }
      }
    });
  }

  static void _downloadIsolate(Map data) async {
    final sendPort = data['sendPort'] as SendPort;
    final comic = data['comic'] as DownloadComic;
    final chapters = data['chapters'] as List<DownloadChapter>;
    final documentsPath = data['documentsPath'] as String;
    final startCompleted = data['completed'] as int;

    final dio = Dio();
    final cancelToken = CancelToken();

    try {
      int completed = startCompleted;
      int i = 0;

      for (var chapter in chapters) {
        for (var image in chapter.images) {
          if (i++ < completed) {
            continue;
          }

          final path = p.join(
            documentsPath,
            'comics',
            comic.title,
            chapter.title,
            image.originalName,
          );

          await _downloadImageIsolate(dio, image.url, path, cancelToken);
          completed++;

          // 发送进度更新
          sendPort.send({'progress': true, 'completed': completed});
        }
      }

      // 发送完成通知
      sendPort.send({'completed': true});
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }

  static Future<void> _downloadImageIsolate(
    Dio dio,
    String url,
    String path,
    CancelToken cancelToken,
  ) async {
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

  void pause() {
    if (!_isPaused) {
      _isPaused = true;
      _cancelToken.cancel('Paused by user');
      _cleanupIsolate();
      _statusController.add('paused');
    }
  }

  void resume() {
    if (_isPaused && !_isCompleted) {
      _isPaused = false;
      _startDownloadInBackground();
    }
  }

  void cancel() {
    _cancelToken.cancel('Cancelled by user');
    _cleanupIsolate();
    _progressController.close();
    _statusController.close();
  }

  void _cleanupIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
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

// enum DownloadStatus { queued, downloading, paused, completed, failed }
