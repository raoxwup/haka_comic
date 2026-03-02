import 'dart:async';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Log {
  static Logger _logger = Logger();

  static late String _logsPath;

  static Future<void> initialize() async {
    try {
      _logsPath = p.join((await getApplicationCacheDirectory()).path, 'logs');

      _logger = Logger(
        printer: PrettyPrinter(
          lineLength: 120,
          colors: false,
          printEmojis: false,
          dateTimeFormat: DateTimeFormat.dateAndTime,
        ),
        output: MultiOutput([
          ConsoleOutput(),
          AdvancedFileOutput(path: _logsPath, maxRotatedFilesCount: 5),
        ]),
      );
    } catch (e, st) {
      _logger.e('Failed to initialize logger', error: e, stackTrace: st);
    }
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
