import 'dart:convert';
import 'dart:io';

import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/local_favorites_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';
import 'package:haka_comic/rust/api/compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 备份文件名（WebDAV 和本地备份统一使用）
const backupFileName = 'backup.zip';

/// 执行数据备份：将所有 Helper 数据库 + 分类黑名单导出到临时目录的 backup 文件夹
Future<void> performBackup() async {
  await Future.wait([
    ImagesHelper().backup(),
    HistoryHelper().backup(),
    ReadRecordHelper().backup(),
    LocalFavoritesHelper().backup(),
    TagBlockHelper().backup(),
    WordBlockHelper().backup(),
    _backupBlacklist(),
  ]);
}

/// 将临时目录中的 backup 文件夹打包为 zip 并返回
Future<File> makeBackupZip() async {
  final tempDir = await getTemporaryDirectory();
  final backupDir = Directory(p.join(tempDir.path, 'backup'));
  final zipFile = File(p.join(tempDir.path, backupFileName));
  await compress(
    sourceFolderPath: backupDir.path,
    outputZipPath: zipFile.path,
    compressionMethod: CompressionMethod.deflated,
  );
  return zipFile;
}

/// 执行完整备份流程并保存 zip 到指定路径
Future<File> backupToPath(String outputPath) async {
  await performBackup();
  final zipFile = await makeBackupZip();
  final dest = File(outputPath);
  if (await dest.exists()) {
    await dest.delete();
  }
  await zipFile.copy(outputPath);
  return dest;
}

/// 解压 backup.zip 并恢复所有数据（兼容旧版备份：缺失文件静默跳过）
Future<void> restoreFromZip(File zipFile) async {
  final tempDir = await getTemporaryDirectory();
  final restoreDir = Directory(p.join(tempDir.path, 'restore'));

  // 清理旧的恢复目录
  if (await restoreDir.exists()) {
    await restoreDir.delete(recursive: true);
  }
  await restoreDir.create(recursive: true);

  // 解压
  await decompress(
    sourceZipPath: zipFile.path,
    outputFolderPath: restoreDir.path,
  );

  // 恢复各数据库（仅当文件存在于解压目录中）
  final restores = <Future<void>>[];
  void addRestore<T extends Object>(
    T helper, {
    required String dbName,
    required Future<void> Function(T, File) restoreFn,
  }) {
    final file = File(p.join(restoreDir.path, dbName));
    if (file.existsSync()) {
      restores.add(restoreFn(helper, file));
    }
  }

  addRestore(ImagesHelper(), dbName: ImagesHelper().dbName, restoreFn: (h, f) => h.restore(f));
  addRestore(HistoryHelper(), dbName: HistoryHelper().dbName, restoreFn: (h, f) => h.restore(f));
  addRestore(ReadRecordHelper(), dbName: ReadRecordHelper().dbName, restoreFn: (h, f) => h.restore(f));
  addRestore(LocalFavoritesHelper(), dbName: LocalFavoritesHelper().dbName, restoreFn: (h, f) => h.restore(f));
  addRestore(TagBlockHelper(), dbName: TagBlockHelper().dbName, restoreFn: (h, f) => h.restore(f));
  addRestore(WordBlockHelper(), dbName: WordBlockHelper().dbName, restoreFn: (h, f) => h.restore(f));

  await Future.wait(restores);

  // 恢复分类黑名单
  await _restoreBlacklist(restoreDir);
}

// ——— 内部辅助 ———

Future<void> _backupBlacklist() async {
  final tempDir = await getTemporaryDirectory();
  final backupDir = Directory(p.join(tempDir.path, 'backup'));
  if (!await backupDir.exists()) {
    await backupDir.create(recursive: true);
  }

  final file = File(p.join(backupDir.path, 'blacklist.json'));
  final json = const JsonEncoder.withIndent('  ').convert({
    'blacklist': AppConf().blacklist,
  });
  await file.writeAsString(json, flush: true);
}

Future<void> _restoreBlacklist(Directory restoreDir) async {
  final file = File(p.join(restoreDir.path, 'blacklist.json'));
  if (await file.exists()) {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final categories = (json['blacklist'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    AppConf().blacklist = categories;
  }
}
