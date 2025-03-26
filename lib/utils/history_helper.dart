import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:sqlite3/sqlite3.dart';

class HistoryHelper with ChangeNotifier {
  static final _instance = HistoryHelper._();

  static String get _dbPath => '${SetupConf.instance.dataPath}/history.db';

  HistoryHelper._();

  static HistoryHelper get instance => _instance;

  Future<void> initialize() async {
    await compute(_createDatabase, _dbPath);
  }

  static void _createDatabase(String path) {
    final db = sqlite3.open(path);
    db.execute('''
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

    db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_history_timestamp 
      AFTER UPDATE ON history 
      BEGIN
        UPDATE history SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
      END;
    ''');

    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_updated_at ON history (updated_at);
    ''');

    db.dispose();
  }

  Future<void> insert(Comic comic) async {
    await compute(_insertComic, [_dbPath, _comicToMap(comic)]);
    notifyListeners();
  }

  static void _insertComic(List<dynamic> args) {
    final db = sqlite3.open(args[0] as String);
    final comic = args[1] as Map<String, dynamic>;

    final stmt = db.prepare('''
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
      ON CONFLICT(cid) DO UPDATE SET
        title = excluded.title,
        author = excluded.author,
        total_views = excluded.total_views,
        total_likes = excluded.total_likes,
        pages_count = excluded.pages_count,
        eps_count = excluded.eps_count,
        finished = excluded.finished,
        categories = excluded.categories,
        file_server = excluded.file_server,
        path = excluded.path,
        original_name = excluded.original_name,
        likes_count = excluded.likes_count
    ''');

    stmt.execute([
      comic['id'],
      comic['title'],
      comic['author'],
      comic['totalViews'],
      comic['totalLikes'],
      comic['pagesCount'],
      comic['epsCount'],
      comic['finished'],
      comic['categories'],
      comic['fileServer'],
      comic['path'],
      comic['originalName'],
      comic['likesCount'],
    ]);

    stmt.dispose();
    db.dispose();
  }

  Future<void> delete(Doc doc) async {
    await compute(_deleteComic, [_dbPath, doc.uid]);
    notifyListeners();
  }

  static void _deleteComic(List<dynamic> args) {
    final db = sqlite3.open(args[0] as String);
    final stmt = db.prepare('DELETE FROM history WHERE cid = ?');
    stmt.execute([args[1]]);
    stmt.dispose();
    db.dispose();
  }

  Future<void> deleteAll() async {
    await compute(_deleteAllComics, _dbPath);
    notifyListeners();
  }

  static void _deleteAllComics(String path) {
    final db = sqlite3.open(path);
    final stmt = db.prepare('DELETE FROM history');
    stmt.execute();
    stmt.dispose();
    db.dispose();
  }

  Future<List<HistoryDoc>> query({DateTime? lastUpdatedAt}) async {
    final results = await compute(_queryComics, [
      _dbPath,
      lastUpdatedAt?.toIso8601String(),
    ]);
    return results.map((map) => HistoryDoc.fromJson(map)).toList();
  }

  static List<Map<String, dynamic>> _queryComics(List<dynamic> args) {
    final db = sqlite3.open(args[0] as String);
    final lastUpdatedAtStr = args[1] as String?;

    DateTime? lastUpdatedAt;
    if (lastUpdatedAtStr != null) {
      lastUpdatedAt = DateTime.parse(lastUpdatedAtStr); // 反序列化
    }

    final query = StringBuffer('''
      SELECT * FROM history 
    ''');

    final params = <dynamic>[];
    if (lastUpdatedAt != null) {
      query.write(' WHERE updated_at < ? ');
      params.add(lastUpdatedAt.toIso8601String());
    }

    query.write(' ORDER BY updated_at DESC, id DESC LIMIT 100 ');

    final resultSet = db.select(query.toString(), params);

    final List<Map<String, dynamic>> results = [];

    for (final row in resultSet) {
      results.add({
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
        "updatedAt": row["updated_at"],
        "createdAt": row["created_at"],
      });
    }

    db.dispose();
    return results;
  }

  Future<int> count() async {
    return await compute(_countComics, _dbPath);
  }

  static int _countComics(String path) {
    final db = sqlite3.open(path);
    final resultSet = db.select('SELECT COUNT(*) FROM history');
    db.dispose();
    return resultSet.first["COUNT(*)"] as int;
  }

  static Map<String, dynamic> _comicToMap(Comic comic) {
    return {
      'id': comic.id,
      'title': comic.title,
      'author': comic.author,
      'totalViews': comic.totalViews,
      'totalLikes': comic.totalLikes,
      'pagesCount': comic.pagesCount,
      'epsCount': comic.epsCount,
      'finished': comic.finished ? 1 : 0,
      'categories': jsonEncode(comic.categories),
      'fileServer': comic.thumb.fileServer,
      'path': comic.thumb.path,
      'originalName': comic.thumb.originalName,
      'likesCount': comic.likesCount,
    };
  }
}
