import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:sqlite3/sqlite3.dart';

class HistoryHelper with ChangeNotifier {
  static final _instance = HistoryHelper._();

  late Database _db;

  bool _isInitialized = false;

  HistoryHelper._() {
    if (_isInitialized) return;
    _isInitialized = true;
    _db = sqlite3.open('${SetupConf.instance.dataPath}/history.db');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id INTEGER PRIMARY KEY,
        cid TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        author TEXT,
        total_views INTEGER DEFAULT 0,
        total_likes INTEGER,
        pages_count INTEGER DEFAULT 0,
        eps_count INTEGER DEFAULT 0,
        finished INTEGER DEFAULT 0,
        categories TEXT NOT NULL,
        file_server TEXT NOT NULL,
        path TEXT NOT NULL,
        original_name TEXT NOT NULL,
        likes_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    _db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_history_timestamp 
      AFTER UPDATE ON history 
      BEGIN
        UPDATE history SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
      END;
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_created_at ON history (created_at)
    ''');
  }

  static HistoryHelper get instance => _instance;

  void close() => _db.dispose();

  void insert(Comic comic) {
    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO history (
        cid,
        title,
        author,
        total_views,
        total_likes,
        pages_count,
        eps_count,
        finished,
        categories,
        file_server,
        path,
        original_name,
        likes_count
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      comic.id,
      comic.title,
      comic.author,
      comic.totalViews,
      comic.totalLikes,
      comic.pagesCount,
      comic.epsCount,
      comic.finished ? 1 : 0,
      jsonEncode(comic.categories),
      comic.thumb.fileServer,
      comic.thumb.path,
      comic.thumb.originalName,
      comic.likesCount,
    ]);
    stmt.dispose();
    notifyListeners();
  }

  void delete(Doc doc) {
    final stmt = _db.prepare('DELETE FROM history WHERE cid = ?');
    stmt.execute([doc.uid]);
    stmt.dispose();
  }

  void deleteAll() {
    final stmt = _db.prepare('DELETE FROM history');
    stmt.execute([]);
    stmt.dispose();
  }

  List<Doc> query(int page) {
    final ResultSet resultSet = _db.select(
      'SELECT * FROM history ORDER BY created_at DESC LIMIT 100 OFFSET ?',
      [page - 1],
    );
    final List<Doc> docs = [];
    for (final row in resultSet) {
      docs.add(
        Doc.fromJson({
          "id": row["cid"],
          "title": row["title"],
          "author": row["author"],
          "totalViews": row["total_views"],
          "totalLikes": row["total_likes"],
          "pagesCount": row["pages_count"],
          "epsCount": row["eps_count"],
          "finished": row["finished"] == 1,
          "categories": jsonDecode(row["categories"]),
          "thumb": {
            "fileServer": row["file_server"],
            "path": row["path"],
            "originalName": row["original_name"],
          },
          "likesCount": row["likes_count"],
          "_id": row["cid"],
        }),
      );
    }
    return docs;
  }

  int count() {
    final resultSet = _db.select('SELECT COUNT(*) FROM history');
    return resultSet.first["COUNT(*)"] as int;
  }
}
