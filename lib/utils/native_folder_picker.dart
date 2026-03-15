import 'package:flutter/services.dart';

class PickedFolderSnapshotFile {
  final String name;
  final String relativePath;
  final String localPath;
  final int size;
  final String? mimeType;

  const PickedFolderSnapshotFile({
    required this.name,
    required this.relativePath,
    required this.localPath,
    required this.size,
    required this.mimeType,
  });

  factory PickedFolderSnapshotFile.fromMap(Map<Object?, Object?> map) {
    return PickedFolderSnapshotFile(
      name: map['name'] as String? ?? '',
      relativePath: map['relativePath'] as String? ?? '',
      localPath: map['localPath'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      mimeType: map['mimeType'] as String?,
    );
  }
}

class PickedFolderSnapshot {
  final String name;
  final String localPath;
  final List<PickedFolderSnapshotFile> files;

  const PickedFolderSnapshot({
    required this.name,
    required this.localPath,
    required this.files,
  });

  factory PickedFolderSnapshot.fromMap(Map<Object?, Object?> map) {
    final rawFiles = map['files'] as List<Object?>? ?? const [];
    return PickedFolderSnapshot(
      name: map['name'] as String? ?? '',
      localPath: map['localPath'] as String? ?? '',
      files: rawFiles
          .whereType<Map<Object?, Object?>>()
          .map(PickedFolderSnapshotFile.fromMap)
          .toList(),
    );
  }
}

class NativeFolderPicker {
  static const MethodChannel _channel = MethodChannel(
    'haka_comic/folder_picker',
  );

  static Future<PickedFolderSnapshot?> pickDirectorySnapshot({
    bool recursive = true,
  }) async {
    final result = await _channel.invokeMethod<Object?>(
      'pickDirectorySnapshot',
      {'recursive': recursive},
    );
    if (result == null) {
      return null;
    }

    if (result is! Map<Object?, Object?>) {
      throw const FormatException('Invalid folder snapshot result');
    }

    return PickedFolderSnapshot.fromMap(result);
  }
}
