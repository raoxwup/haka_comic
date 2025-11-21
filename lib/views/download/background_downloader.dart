import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';

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

  static Future<void> initialize() async {
    final path = await getDownloadDirectory();
    _downloadPath = path;

    final downloadTaskHelper = DownloadTaskHelper();
    await downloadTaskHelper.initialize();

    final allTask = await downloadTaskHelper.getAll();
    tasks.addAll(allTask);
  }

  static void receive(WorkerMessage message) {
    print(message.type);
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
}
