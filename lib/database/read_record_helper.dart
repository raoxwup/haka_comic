import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations =
    SqliteMigrations()..add(
      SqliteMigration(1, (tx) async {
        await tx.execute('''
          CREATE TABLE IF NOT EXISTS read_record (
            id INTEGER PRIMARY KEY,
            cid TEXT UNIQUE NOT NULL,
            chapter_id TEXT NOT NULL,
            chapter_title TEXT NOT NULL,
            page_no INTEGER NOT NULL
          );
        ''');

        await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_read_record_cid
          ON read_record (cid);
        ''');
      }),
    );

class ReadRecordHelper with ChangeNotifier {
  ReadRecordHelper._internal();

  static final _instance = ReadRecordHelper._internal();

  factory ReadRecordHelper() => _instance;

  late SqliteDatabase _db;
  String get dbPath => '${SetupConf.dataPath}/read_record.db';

  Future<void> initialize() async {
    _db = SqliteDatabase(path: dbPath);
    await migrations.migrate(_db);
  }

  Future<void> insert(ComicReadRecord record) async {
    try {
      await _db.writeTransaction((tx) async {
        await tx.execute(
          '''
          INSERT INTO read_record (cid, chapter_id, chapter_title, page_no)
          VALUES (?, ?, ?, ?)
          ON CONFLICT(cid) DO UPDATE SET
            chapter_id = excluded.chapter_id,
            chapter_title = excluded.chapter_title,
            page_no = excluded.page_no
          ''',
          [record.cid, record.chapterId, record.chapterTitle, record.pageNo],
        );
      });
      notifyListeners();
    } catch (e) {
      Log.error('insert read record error', e);
      rethrow;
    }
  }

  Future<ComicReadRecord?> query(String cid) async {
    final result = await _db.getOptional(
      'SELECT * FROM read_record WHERE cid = ?',
      [cid],
    );
    return result == null ? null : ComicReadRecord.fromJson(result);
  }

  Future<File> backup() async {
    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, 'read_record.db');
    await _db.execute('VACUUM INTO ?', [path]);
    return File(path);
  }

  Future<void> restore(File file) async {
    // 关闭当前数据库
    await _db.close();
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

class ComicReadRecord {
  final String cid;
  final String chapterId;
  final String chapterTitle;
  final int pageNo;

  ComicReadRecord({
    required this.cid,
    required this.chapterId,
    required this.pageNo,
    required this.chapterTitle,
  });

  Map<String, dynamic> toJson() => {
    'cid': cid,
    'chapterId': chapterId,
    'pageNo': pageNo,
    'chapterTitle': chapterTitle,
  };

  factory ComicReadRecord.fromJson(Map<String, dynamic> json) =>
      ComicReadRecord(
        cid: json['cid'] as String,
        chapterId: json['chapter_id'] as String,
        chapterTitle: json['chapter_title'] as String,
        pageNo: json['page_no'] as int,
      );
}
