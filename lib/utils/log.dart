import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:jiffy/jiffy.dart';

class HaKaLog {
  final String level;
  final String message;
  final String? error;
  final String? stackTrace;
  final String time;

  const HaKaLog({
    required this.level,
    required this.message,
    required this.error,
    required this.stackTrace,
    required this.time,
  });

  @override
  String toString() {
    return '[$time][$level]\n$message\n$error\n$stackTrace';
  }
}

class Log {
  static Logger _logger = Logger();

  static late String _logsPath;

  static Future<void> initialize() async {
    try {
      _logsPath = p.join((await getApplicationCacheDirectory()).path, 'logs');

      _logger = Logger(
        printer: HaKaPrinter(),
        output: MultiOutput([
          ConsoleOutput(),
          AdvancedFileOutput(path: _logsPath, maxRotatedFilesCount: 3),
        ]),
      );
    } catch (e, st) {
      _logger.e('Failed to initialize logger', error: e, stackTrace: st);
    }
  }

  static Future<List<HaKaLog>> _parseLogs(String path) async {
    final file = File(path);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final entries = content
        .split('<<<LOG_START>>>')
        .where((e) => e.contains('<<<LOG_END>>>'));
    return entries.map((e) {
      final jsonStr = e.replaceAll('<<<LOG_END>>>', '').trim();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return HaKaLog(
        error: json['error'],
        message: json['message'],
        time: json['time'],
        stackTrace: json['stackTrace'],
        level: json['level'],
      );
    }).toList();
  }

  static Future<List<HaKaLog>> getLogs() async {
    try {
      final path = p.join(_logsPath, 'latest.log');
      final logs = await compute(_parseLogs, path);
      return logs;
    } catch (e, st) {
      _logger.e('Failed to get logs', error: e, stackTrace: st);
      return [];
    }
  }

  static Future<void> clearLogs() async {
    await Directory(_logsPath).delete(recursive: true);
  }

  static void t(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) => _logger.t(message, error: error, stackTrace: stackTrace, time: time);

  static void d(
    String message,
    dynamic data, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) => _logger.d(
    '$message\n$data',
    error: error,
    stackTrace: stackTrace,
    time: time,
  );

  static void i(
    String message,
    dynamic data, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) => _logger.i(
    '$message\n$data',
    error: error,
    stackTrace: stackTrace,
    time: time,
  );

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) => _logger.e(message, error: error, stackTrace: stackTrace, time: time);

  static void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) => _logger.w(message, error: error, stackTrace: stackTrace, time: time);

  static void f(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) => _logger.f(message, error: error, stackTrace: stackTrace, time: time);
}

class HaKaPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final buffer = <String>[];
    final now = Jiffy.now().format(pattern: 'yyyy-MM-dd HH:mm:ss');
    final json = {
      'time': now,
      'level': event.level.name,
      'message': event.message.toString(),
      'error': event.error?.toString(),
      'stackTrace': event.stackTrace?.toString(),
    };
    buffer.add('<<<LOG_START>>>');
    buffer.add(jsonEncode(json));
    buffer.add('<<<LOG_END>>>');
    return buffer;
  }
}
