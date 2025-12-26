import 'dart:io';
import 'package:haka_comic/database/download_task_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:path/path.dart' as p;

Future<List<ImageBase>> fetchLocalImages(
  FetchChapterImagesPayload payload,
) async {
  final helper = DownloadTaskHelper();
  final comic = await helper.getDownloadComic(payload.id);
  final chapters = await helper.getDownloadChapters(payload.id);
  final chapter = chapters.firstWhere(
    (element) => element.order == payload.order,
    orElse: () => chapters.first,
  );
  final downloadDir = await getDownloadDirectory();

  final comicPath = p.join(downloadDir, comic.title.legalized);
  if (!await Directory(comicPath).exists()) {
    throw Exception('漫画不存在，检查是否已被删除');
  }

  final chapterPath = p.join(comicPath, chapter.title.legalized);
  final chapterDir = Directory(chapterPath);
  if (!await chapterDir.exists()) {
    throw Exception('漫画不存在，检查是否已被删除');
  }

  const imageExts = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

  final files = await chapterDir
      .list()
      .where(
        (entity) =>
            entity is File &&
            imageExts.contains(p.extension(entity.path).toLowerCase()),
      )
      .cast<File>()
      .toList();

  // 可选：按文件名排序（很常见）
  files.sort((a, b) => a.path.compareTo(b.path));

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
