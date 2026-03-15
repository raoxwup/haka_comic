import 'dart:io';

import 'package:flutter/services.dart';

class SaveToFolderIos {
  static const MethodChannel _channel = MethodChannel(
    'haka_comic/ios_file_saver',
  );

  static Future<bool> copy(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File does not exist at path: $path');
    }

    try {
      final result = await _channel.invokeMethod<bool>('copy', {'path': path});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
