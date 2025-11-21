import 'dart:io';
import 'package:haka_comic/config/setup_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:path/path.dart' as p;

mixin DbBackupMixin on Object {
  late SqliteDatabase _db;
  SqliteDatabase get db => _db;
  String get dbName;
  String get dbPath => p.join(SetupConf.dataPath, dbName);

  Future<void> initialize() async {
    _db = SqliteDatabase(path: dbPath);
  }

  Future<File> backup() async {
    final tempDir = await getTemporaryDirectory();
    final backupDir = Directory(p.join(tempDir.path, 'backup'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final path = p.join(backupDir.path, dbName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await db.execute('VACUUM INTO ?', [path]);
    return File(path);
  }

  Future<void> restore(File file) async {
    // 关闭当前数据库
    await db.close();

    // 删除旧文件
    final files = [File(dbPath), File('$dbPath-wal'), File('$dbPath-shm')];
    for (var file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }

    // 复制新文件
    await file.copy(dbPath);

    // 重新打开数据库
    await initialize();
  }
}
