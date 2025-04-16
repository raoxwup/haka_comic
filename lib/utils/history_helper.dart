import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations =
    SqliteMigrations()..add(
      SqliteMigration(1, (tx) async {
        await tx.execute('''
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

        await tx.execute('''
          CREATE TRIGGER IF NOT EXISTS update_history_timestamp 
          AFTER UPDATE ON history 
          BEGIN
            UPDATE history SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
          END;
        ''');

        await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_updated_at ON history (updated_at);
        ''');
      }),
    );

class HistoryHelper with ChangeNotifier {
  static final _instance = HistoryHelper._create();
  static String get _dbPath => '${SetupConf.instance.dataPath}/history.db';

  factory HistoryHelper() => _instance;
  static HistoryHelper get instance => _instance;

  late SqliteDatabase _db;

  HistoryHelper._create();

  Future<void> initialize() async {
    _db = SqliteDatabase(path: _dbPath);
    await migrations.migrate(_db);
  }

  Future<void> insert(Comic comic) async {
    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
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
        ''',
        [
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
        ],
      );
    });
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _db.execute('DELETE FROM history WHERE cid = ?', [id]);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    await _db.execute('DELETE FROM history');
    notifyListeners();
  }

  Future<List<HistoryDoc>> query(int page) async {
    final result = await _db.getAll(
      'SELECT * FROM history ORDER BY updated_at DESC LIMIT 20 OFFSET ?',
      [(page - 1) * 20],
    );

    return result.map((row) {
      return HistoryDoc.fromJson({
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
    }).toList();
  }

  Future<int> count() async {
    final result = await _db.get('SELECT COUNT(*) FROM history');
    return result['COUNT(*)'] as int;
  }
}
