import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android export builds files inside a prepared temp directory', () {
    final source = File('lib/utils/comic_exporter.dart').readAsStringSync();
    final androidExportBody = source.substring(
      source.indexOf('static Future<void> _exportForAndroid'),
      source.indexOf('static Future<void> _buildFile'),
    );

    expect(
      androidExportBody,
      contains('final tempDir = await _createCleanTempDirectory();'),
    );
    expect(
      androidExportBody,
      contains('final destPath = p.join(tempDir.path, fileName);'),
    );
    expect(
      androidExportBody,
      isNot(contains('p.join(cacheDir.path, exportFileTempDir, fileName)')),
    );
  });
}
