import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

extension FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) predicate) {
    for (final element in this) {
      if (predicate(element)) return element;
    }
    return null;
  }
}

class Log {
  static const int _maxLogFileBytes = 5 * 1024 * 1024;
  static const int _maxBackupFiles = 3;

  static Logger _logger = _buildLogger([ConsoleOutput()]);
  static bool _initialized = false;
  static File? _logFile;

  static Logger get instance => _logger;

  static String? get logFilePath => _logFile?.path;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final outputs = <LogOutput>[ConsoleOutput()];
    try {
      final supportDir = await getApplicationSupportDirectory();
      final logDir = Directory(p.join(supportDir.path, 'logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File(p.join(logDir.path, 'app.log'));
      outputs.add(
        _RollingFileOutput(
          _logFile!,
          maxFileBytes: _maxLogFileBytes,
          maxBackups: _maxBackupFiles,
        ),
      );
    } catch (e, st) {
      debugPrint('Init file logger failed: $e\n$st');
    }

    _logger = _buildLogger(outputs);
  }

  static Logger _buildLogger(List<LogOutput> outputs) {
    return Logger(
      filter: _AllLogFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: false,
        printEmojis: false,
        noBoxingByDefault: true,
      ),
      output: MultiOutput(outputs),
    );
  }

  static void info(String title, Object? content) {
    _logger.i(_combine(title, content));
  }

  static void warning(String title, Object? content) {
    _logger.w(_combine(title, content));
  }

  static void error(String title, Object error, [Object? stackTrace]) {
    final stack = stackTrace is StackTrace ? stackTrace : null;
    _logger.e(title, error: error, stackTrace: stack);
    if (stackTrace != null && stack == null) {
      _logger.e(_combine(title, 'stackTrace: $stackTrace'));
    }
  }

  static void clear() {
    final logFile = _logFile;
    if (logFile == null) return;
    unawaited(_clearFiles(logFile));
  }

  static String _combine(String title, Object? content) {
    if (content == null) return title;
    final text = content.toString();
    if (text.isEmpty) return title;
    return '$title | $text';
  }

  static Future<void> _clearFiles(File logFile) async {
    try {
      if (await logFile.exists()) {
        await logFile.writeAsString('');
      }
      for (var i = 1; i <= _maxBackupFiles; i++) {
        final backup = File('${logFile.path}.$i');
        if (await backup.exists()) {
          await backup.delete();
        }
      }
    } catch (e, st) {
      debugPrint('Clear log files failed: $e\n$st');
    }
  }
}

class _AllLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _RollingFileOutput extends LogOutput {
  _RollingFileOutput(
    this._file, {
    required this.maxFileBytes,
    required this.maxBackups,
  });

  final File _file;
  final int maxFileBytes;
  final int maxBackups;

  Future<void> _pending = Future<void>.value();

  @override
  void output(OutputEvent event) {
    if (event.lines.isEmpty) return;
    final chunk = '${event.lines.join('\n')}\n';
    _pending = _pending
        .then((_) => _append(chunk))
        .catchError((error, stackTrace) {});
  }

  Future<void> _append(String chunk) async {
    await _rotateIfNeeded(chunk.length);
    await _file.writeAsString(chunk, mode: FileMode.append, flush: true);
  }

  Future<void> _rotateIfNeeded(int incomingLength) async {
    if (await _file.exists()) {
      final currentLength = await _file.length();
      if (currentLength + incomingLength <= maxFileBytes) return;

      for (var i = maxBackups; i >= 1; i--) {
        final backup = File('${_file.path}.$i');
        if (!await backup.exists()) continue;
        if (i == maxBackups) {
          await backup.delete();
        } else {
          await backup.rename('${_file.path}.${i + 1}');
        }
      }
      await _file.rename('${_file.path}.1');
    }
  }

  @override
  Future<void> destroy() async {
    await _pending;
  }
}
