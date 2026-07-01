import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/native_folder_picker.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:path/path.dart' as p;

const _imageExts = {'.jpg', '.jpeg', '.png', '.webp'};

class LocalComicImportException implements Exception {
  const LocalComicImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PickedLocalComicSource {
  const PickedLocalComicSource({
    required this.folderName,
    required this.directoryPath,
    this.cleanupPath,
  });

  final String folderName;
  final String directoryPath;
  final String? cleanupPath;
}

class LocalComicImporter {
  const LocalComicImporter._();

  static Future<PickedLocalComicSource?> pickSource() async {
    if (isAndroid || isIOS) {
      final snapshot = await NativeFolderPicker.pickDirectorySnapshot();
      if (snapshot == null) {
        return null;
      }

      return PickedLocalComicSource(
        folderName: snapshot.name,
        directoryPath: snapshot.localPath,
        cleanupPath: snapshot.localPath,
      );
    }

    final path = await FilePicker.getDirectoryPath();
    if (path == null) {
      return null;
    }

    return PickedLocalComicSource(
      folderName: p.basename(path),
      directoryPath: path,
    );
  }

  static Future<void> cleanupSource(PickedLocalComicSource source) async {
    final cleanupPath = source.cleanupPath;
    if (cleanupPath == null) {
      return;
    }

    final directory = Directory(cleanupPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  static Future<ComicDownloadTask> importSource(
    PickedLocalComicSource source, {
    required Iterable<String> existingTitles,
  }) async {
    Directory? tempDir;

    try {
      final sourceDir = Directory(source.directoryPath);
      if (!await sourceDir.exists()) {
        throw const LocalComicImportException('所选文件夹不存在');
      }

      final chapterPlans = await _buildChapterPlans(sourceDir);
      if (chapterPlans.isEmpty) {
        throw const LocalComicImportException('没有找到漫画图片');
      }

      final downloadRootPath = await getDownloadDirectory();
      await Directory(downloadRootPath).create(recursive: true);

      final title = await _resolveAvailableTitle(
        baseTitle: source.folderName,
        downloadRootPath: downloadRootPath,
        existingTitles: existingTitles,
      );

      final idSeed =
          '${source.directoryPath}|${DateTime.now().microsecondsSinceEpoch}';
      final digest = sha1.convert(utf8.encode(idSeed)).toString();
      final taskId = 'import:$digest';
      final targetDir = Directory(p.join(downloadRootPath, title.legalized));

      tempDir = Directory(p.join(downloadRootPath, '.import_$digest'));
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      final chapters = <DownloadChapter>[];
      String? coverPath;
      var totalImages = 0;

      for (
        var chapterIndex = 0;
        chapterIndex < chapterPlans.length;
        chapterIndex++
      ) {
        final plan = chapterPlans[chapterIndex];
        final order = chapterIndex + 1;
        final chapterTitle = _normalizeTitle(plan.title, fallback: '第$order章');
        final chapter = DownloadChapter(
          id: '$taskId:$order',
          title: chapterTitle,
          order: order,
        );
        final chapterFolderName = '${chapter.order}_${chapter.title.legalized}';
        final tempChapterDir = Directory(
          p.join(tempDir.path, chapterFolderName),
        );
        await tempChapterDir.create(recursive: true);

        for (
          var imageIndex = 0;
          imageIndex < plan.images.length;
          imageIndex++
        ) {
          final sourceImage = plan.images[imageIndex];
          final ext = p.extension(sourceImage.path).toLowerCase();
          final fileName =
              '${(imageIndex + 1).toString().padLeft(4, '0')}${ext.isEmpty ? '.jpg' : ext}';
          final tempImagePath = p.join(tempChapterDir.path, fileName);

          await sourceImage.copy(tempImagePath);

          coverPath ??= p.join(targetDir.path, chapterFolderName, fileName);
          totalImages += 1;
          chapter.images.add(
            ImageDetail(
              fileServer: 'local',
              path: '$taskId/$order/$fileName',
              originalName: fileName,
            ),
          );
        }

        chapters.add(chapter);
      }

      if (await targetDir.exists()) {
        throw const LocalComicImportException('目标漫画目录已存在');
      }

      await tempDir.rename(targetDir.path);
      tempDir = null;

      return ComicDownloadTask(
          comic: DownloadComic(
            id: taskId,
            title: title,
            cover: coverPath ?? '',
          ),
          chapters: chapters,
          source: DownloadTaskSource.import,
        )
        ..total = totalImages
        ..completed = totalImages
        ..status = DownloadTaskStatus.completed;
    } finally {
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  static Future<List<_ChapterImportPlan>> _buildChapterPlans(
    Directory sourceDir,
  ) async {
    final childDirs = await sourceDir
        .list(followLinks: false)
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();

    childDirs.sort(_compareEntitiesByName);

    final chapterPlans = <_ChapterImportPlan>[];
    for (final childDir in childDirs) {
      final images = await _listImages(childDir);
      if (images.isEmpty) {
        continue;
      }

      chapterPlans.add(
        _ChapterImportPlan(title: p.basename(childDir.path), images: images),
      );
    }

    if (chapterPlans.isNotEmpty) {
      return chapterPlans;
    }

    final rootImages = await _listImages(sourceDir);
    if (rootImages.isEmpty) {
      return const [];
    }

    return [_ChapterImportPlan(title: '第1章', images: rootImages)];
  }

  static Future<List<File>> _listImages(Directory directory) async {
    final files = await directory
        .list(followLinks: false)
        .where(
          (entity) =>
              entity is File &&
              _imageExts.contains(p.extension(entity.path).toLowerCase()),
        )
        .cast<File>()
        .toList();

    files.sort(_compareEntitiesByName);
    return files;
  }

  static Future<String> _resolveAvailableTitle({
    required String baseTitle,
    required String downloadRootPath,
    required Iterable<String> existingTitles,
  }) async {
    final normalizedBaseTitle = _normalizeTitle(baseTitle, fallback: '导入漫画');
    final usedLegalNames = existingTitles
        .map((title) => title.legalized.toLowerCase())
        .toSet();

    var candidate = normalizedBaseTitle;
    var suffix = 2;

    while (true) {
      final legalName = candidate.legalized;
      final targetPath = p.join(downloadRootPath, legalName);

      if (!usedLegalNames.contains(legalName.toLowerCase()) &&
          !await Directory(targetPath).exists()) {
        return candidate;
      }

      candidate = '$normalizedBaseTitle ($suffix)';
      suffix += 1;
    }
  }

  static String _normalizeTitle(String value, {required String fallback}) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static int _compareEntitiesByName(FileSystemEntity a, FileSystemEntity b) {
    return _compareNaturally(
      p.basename(a.path).toLowerCase(),
      p.basename(b.path).toLowerCase(),
    );
  }

  static int _compareNaturally(String a, String b) {
    final pattern = RegExp(r'\d+|\D+');
    final aParts = pattern.allMatches(a).map((match) => match[0]!).toList();
    final bParts = pattern.allMatches(b).map((match) => match[0]!).toList();
    final length = aParts.length < bParts.length
        ? aParts.length
        : bParts.length;

    for (var index = 0; index < length; index++) {
      final aPart = aParts[index];
      final bPart = bParts[index];
      final aNumber = int.tryParse(aPart);
      final bNumber = int.tryParse(bPart);

      final compare = aNumber != null && bNumber != null
          ? aNumber.compareTo(bNumber)
          : aPart.compareTo(bPart);

      if (compare != 0) {
        return compare;
      }
    }

    return aParts.length.compareTo(bParts.length);
  }
}

class _ChapterImportPlan {
  const _ChapterImportPlan({required this.title, required this.images});

  final String title;
  final List<File> images;
}
