import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/native_folder_picker.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/views/download/local_comic_files.dart';
import 'package:path/path.dart' as p;

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
    final legalTitle = title.legalized;
    final targetDirPath = p.join(downloadRootPath, legalTitle);
    final tempDirPath = p.join(downloadRootPath, '.import_$digest');

    // 只在主 isolate 里做“规划”（扫描已经完成），封面/总数等元数据也在此确定；
    // 真正的重 I/O（逐张拷贝）放到独立 isolate，避免卡 UI。
    final chapters = <DownloadChapter>[];
    final copyChapters = <_ChapterCopyPlan>[];
    String? coverRelativePath;
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

      final files = <_ImageCopyPlan>[];
      for (
        var imageIndex = 0;
        imageIndex < plan.images.length;
        imageIndex++
      ) {
        final sourceImage = plan.images[imageIndex];
        final ext = p.extension(sourceImage.path).toLowerCase();
        final fileName =
            '${(imageIndex + 1).toString().padLeft(4, '0')}${ext.isEmpty ? '.jpg' : ext}';
        files.add(
          _ImageCopyPlan(sourcePath: sourceImage.path, fileName: fileName),
        );

        // 封面存相对 download 根目录的路径，展示时再拼接，规避沙盒绝对路径失效。
        coverRelativePath ??= p.join(legalTitle, chapterFolderName, fileName);
        totalImages += 1;
      }

      copyChapters.add(
        _ChapterCopyPlan(folderName: chapterFolderName, files: files),
      );
      // 章节图片不入库：本地漫画以文件系统为准，阅读时按目录读取。
      chapters.add(chapter);
    }

    await Isolate.run(
      () => _performCopy(
        _CopyPlan(
          tempDirPath: tempDirPath,
          targetDirPath: targetDirPath,
          chapters: copyChapters,
        ),
      ),
    );

    return ComicDownloadTask(
        comic: DownloadComic(
          id: taskId,
          title: title,
          cover: coverRelativePath ?? '',
        ),
        chapters: chapters,
        source: DownloadTaskSource.import,
      )
      ..total = totalImages
      ..completed = totalImages
      ..status = DownloadTaskStatus.completed;
  }

  static Future<List<_ChapterImportPlan>> _buildChapterPlans(
    Directory sourceDir,
  ) async {
    final childDirs = await sourceDir
        .list(followLinks: false)
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();

    childDirs.sort(compareEntitiesByNaturalName);

    final chapterPlans = <_ChapterImportPlan>[];
    for (final childDir in childDirs) {
      final images = await listImageFiles(childDir);
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

    final rootImages = await listImageFiles(sourceDir);
    if (rootImages.isEmpty) {
      return const [];
    }

    return [_ChapterImportPlan(title: '第1章', images: rootImages)];
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
}

class _ChapterImportPlan {
  const _ChapterImportPlan({required this.title, required this.images});

  final String title;
  final List<File> images;
}

/// 在独立 isolate 中执行拷贝：先写入临时目录，全部成功后整目录 rename 到最终位置，
/// 保证“要么完整出现、要么完全不出现”。中途失败会清理临时目录；进程被杀导致的
/// 残留由 worker 启动时统一清理。
Future<void> _performCopy(_CopyPlan plan) async {
  final tempDir = Directory(plan.tempDirPath);
  try {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    for (final chapter in plan.chapters) {
      final chapterDir = Directory(p.join(tempDir.path, chapter.folderName));
      await chapterDir.create(recursive: true);
      for (final image in chapter.files) {
        await File(
          image.sourcePath,
        ).copy(p.join(chapterDir.path, image.fileName));
      }
    }

    if (await Directory(plan.targetDirPath).exists()) {
      throw const LocalComicImportException('目标漫画目录已存在');
    }

    await tempDir.rename(plan.targetDirPath);
  } catch (_) {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    rethrow;
  }
}

class _CopyPlan {
  const _CopyPlan({
    required this.tempDirPath,
    required this.targetDirPath,
    required this.chapters,
  });

  final String tempDirPath;
  final String targetDirPath;
  final List<_ChapterCopyPlan> chapters;
}

class _ChapterCopyPlan {
  const _ChapterCopyPlan({required this.folderName, required this.files});

  final String folderName;
  final List<_ImageCopyPlan> files;
}

class _ImageCopyPlan {
  const _ImageCopyPlan({required this.sourcePath, required this.fileName});

  final String sourcePath;
  final String fileName;
}
