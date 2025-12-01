import 'package:flutter/services.dart';

class AndroidDownloadSaver {
  static const MethodChannel _channel = MethodChannel(
    'haka_comic/download_saver',
  );

  static Future<void> saveToDownloads({
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    await _channel.invokeMethod('saveFileToDownloads', {
      'sourceFilePath': filePath,
      'fileName': fileName,
      'mimeType': mimeType ?? _getMimeType(fileName),
    });
  }

  static String _getMimeType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.pdf')) return 'application/pdf';
    if (ext.endsWith('.zip')) return 'application/zip';
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }

  static Future<int> getAndroidVersion() async {
    final version = await _channel.invokeMethod<int>('getAndroidVersion');
    if (version == null) {
      throw Exception('Failed to get android version');
    }
    return version;
  }
}
