import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:sqlite3/sqlite3.dart';

class ReadRecordHelper with ChangeNotifier {
  static ReadRecordHelper instance = ReadRecordHelper._internal();

  factory ReadRecordHelper() => instance;

  String get dbPath => '${SetupConf.instance.dataPath}/read_record.db';

  late Database _db;

  ReadRecordHelper._internal() {
    _db = sqlite3.open(dbPath);
    _db.execute('''
      CREATE TABLE IF NOT EXISTS read_record (
        id INTEGER PRIMARY KEY,
        cid TEXT UNIQUE NOT NULL,
        chapter_id TEXT NOT NULL,
        chapter_title TEXT NOT NULL,
        page_no INTEGER NOT NULL
      )
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_read_record_cid
      ON read_record (cid);
    ''');
  }

  void insert(ComicReadRecord record) {
    try {
      _db.execute(
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
      notifyListeners();
    } catch (e) {
      Log.error('insert read record error', e);
      rethrow;
    }
  }

  ComicReadRecord? query(String cid) {
    final result = _db.select('SELECT * FROM read_record WHERE cid = ?', [cid]);
    if (result.isEmpty) return null;
    return ComicReadRecord.fromJson(result.first);
  }

  void close() => _db.dispose();
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
