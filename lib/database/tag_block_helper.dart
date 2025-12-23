import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations = SqliteMigrations()
  ..add(
    SqliteMigration(1, (tx) async {
      await tx.execute('''
          CREATE TABLE IF NOT EXISTS tag_block (
            id INTEGER PRIMARY KEY,
            tag TEXT UNIQUE NOT NULL
          );
        ''');
    }),
  );

class TagBlockHelper with ChangeNotifier {
  TagBlockHelper._internal();

  static final _instance = TagBlockHelper._internal();

  factory TagBlockHelper() => _instance;

  late SqliteDatabase _db;
  String get dbPath => '${SetupConf.dataPath}/tag_block.db';

  Future<void> initialize() async {
    _db = SqliteDatabase(path: dbPath);
    await migrations.migrate(_db);
  }

  Future<void> insert(String tag) async {
    await _db.writeTransaction((tx) async {
      await tx.execute('INSERT OR IGNORE INTO tag_block (tag) VALUES (?)', [
        tag,
      ]);
    });
    notifyListeners();
  }

  Future<void> delete(String tag) async {
    await _db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM tag_block WHERE tag = ?', [tag]);
    });
    notifyListeners();
  }

  Future<List<String>> query() async {
    final result = await _db.getAll('SELECT tag FROM tag_block');
    return result.map((row) => row['tag'] as String).toList();
  }

  Future<bool> contains(String tag) async {
    final result = await _db.getOptional(
      'SELECT 1 FROM tag_block WHERE tag = ?',
      [tag],
    );
    return result != null;
  }

  Future<void> clear() async {
    await _db.execute('DELETE FROM tag_block');
    notifyListeners();
  }
}
