import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:path/path.dart' as p;

final migrations =
    SqliteMigrations()..add(
      SqliteMigration(1, (tx) async {
        await tx.execute('''
          CREATE TABLE IF NOT EXISTS word_block (
            id INTEGER PRIMARY KEY,
            word TEXT UNIQUE NOT NULL
          );
        ''');
      }),
    );

class WordBlockHelper with ChangeNotifier {
  WordBlockHelper._internal();

  static final _instance = WordBlockHelper._internal();

  factory WordBlockHelper() => _instance;

  late SqliteDatabase _db;
  String get dbPath => '${SetupConf.dataPath}/word_block.db';

  Future<void> initialize() async {
    _db = SqliteDatabase(path: dbPath);
    await migrations.migrate(_db);
  }

  Future<void> insert(String word) async {
    await _db.writeTransaction((tx) async {
      await tx.execute('INSERT OR IGNORE INTO word_block (word) VALUES (?)', [
        word,
      ]);
    });
    notifyListeners();
  }

  Future<void> delete(String word) async {
    await _db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM word_block WHERE word = ?', [word]);
    });
    notifyListeners();
  }

  Future<List<String>> query() async {
    final result = await _db.getAll('SELECT word FROM word_block');
    return result.map((row) => row['word'] as String).toList();
  }

  Future<bool> contains(String word) async {
    final result = await _db.getOptional(
      'SELECT 1 FROM word_block WHERE word = ?',
      [word],
    );
    return result != null;
  }

  Future<void> clear() async {
    await _db.execute('DELETE FROM word_block');
    notifyListeners();
  }

  Future<File> backup() async {
    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, 'word_block.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await _db.execute('VACUUM INTO ?', [path]);
    return File(path);
  }

  Future<void> restore(File file) async {
    await _db.close();
    final files = [File(dbPath), File('$dbPath-wal'), File('$dbPath-shm')];
    for (var f in files) {
      if (await f.exists()) {
        await f.delete();
      }
    }
    await file.copy(dbPath);
    await initialize();
  }
}
