import 'dart:io';

import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:path/path.dart' as p;

const _imageExts = {'.jpg', '.jpeg', '.png', '.webp'};

Future<List<ImageBase>> fetchImportImages(
  FetchChapterImagesPayload payload,
) async {
  const importSuffix = '_import';
  final title = payload.id.endsWith(importSuffix)
      ? payload.id.substring(0, payload.id.length - importSuffix.length)
      : payload.id;
  final downloadDir = await getDownloadDirectory();
  final comicDir = Directory(p.join(downloadDir, 'import_comics', title));

  if (!await comicDir.exists()) {
    throw Exception('漫画不存在，检查是否已被删除');
  }

  final files = await comicDir
      .list()
      .where(
        (entity) =>
            entity is File &&
            _imageExts.contains(p.extension(entity.path).toLowerCase()),
      )
      .cast<File>()
      .toList();

  if (files.isEmpty) {
    throw Exception('章节下不存在漫画图片，检查是否已被删除');
  }

  files.sort(
    (a, b) => p
        .basename(a.path)
        .toLowerCase()
        .compareTo(p.basename(b.path).toLowerCase()),
  );

  await Future.delayed(const Duration(milliseconds: 150));

  return files
      .map(
        (file) => LocalImage(
          url: file.path,
          uid: file.path.hashCode.toString(),
          id: file.path.hashCode.toString(),
        ),
      )
      .toList();
}
