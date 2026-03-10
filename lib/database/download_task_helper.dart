import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart' hide SqliteOpenFactory;
import 'package:path/path.dart' as p;
import 'package:haka_comic/database/utils.dart' show SqliteOpenFactory;

final migrations = SqliteMigrations()
  ..add(
    SqliteMigration(1, (tx) async {
      await tx.execute('''
          CREATE TABLE IF NOT EXISTS download_task(
            id TEXT PRIMARY KEY,
            total INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0,
            status TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');

      await tx.execute('''
          CREATE TRIGGER IF NOT EXISTS update_download_task_timestamp 
            AFTER UPDATE ON download_task 
            BEGIN
                UPDATE download_task SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
            END;
        ''');

      await tx.execute('''
          CREATE TABLE IF NOT EXISTS download_comic(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            cover TEXT NOT NULL,
            FOREIGN KEY (id) REFERENCES download_task (id) ON DELETE CASCADE
          )
        ''');

      await tx.execute('''
          CREATE TABLE IF NOT EXISTS download_chapter(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            chapter_order INTEGER NOT NULL,
            task_id TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (task_id) REFERENCES download_task (id) ON DELETE CASCADE
          )
        ''');

      await tx.execute('''
          CREATE TABLE IF NOT EXISTS chapter_image(
            id INTEGER PRIMARY KEY,
            file_server TEXT NOT NULL,
            path TEXT NOT NULL,
            original_name TEXT NOT NULL,
            chapter_id TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (chapter_id) REFERENCES download_chapter (id) ON DELETE CASCADE,
            CONSTRAINT unique_file_server_path UNIQUE (file_server, path)
          )
        ''');

      await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_download_chapter_task_id 
          ON download_chapter(task_id)
        ''');

      await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_chapter_image_chapter_id 
          ON chapter_image(chapter_id)
        ''');
    }),
  );

class DownloadTaskHelper with ChangeNotifier {
  DownloadTaskHelper._create();

  static final _instance = DownloadTaskHelper._create();

  factory DownloadTaskHelper() => _instance;

  late SqliteDatabase _db;

  bool isInitialized = false;

  String get dbName => 'download_task.db';

  Future<void> initialize() async {
    if (isInitialized) return;
    final dbPath = (await getApplicationSupportDirectory()).path;
    _db = SqliteDatabase.withFactory(
      SqliteOpenFactory(path: p.join(dbPath, dbName)),
    );
    await migrations.migrate(_db);
    isInitialized = true;
  }

  /// 轻量级进度更新：仅更新任务状态和完成进度
  Future<void> updateTaskProgress(ComicDownloadTask task) async {
    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
          UPDATE download_task 
          SET completed = ?, status = ?
          WHERE id = ?
        ''',
        [task.completed, task.status.name, task.comic.id],
      );
    });
  }

  /// 插入或者更新单个下载任务
  Future<void> insertSingleTask(ComicDownloadTask task) => insert([task]);

  /// 插入或者更新下载任务列表
  Future<void> insert(List<ComicDownloadTask> tasks) async {
    notifyListeners();
    await _db.writeTransaction((tx) async {
      for (var task in tasks) {
        await tx.execute(
          '''
            INSERT INTO download_task (id, total, completed, status)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              total = excluded.total,
              completed = excluded.completed,
              status = excluded.status
          ''',
          [task.comic.id, task.total, task.completed, task.status.name],
        );

        await tx.execute(
          '''
            INSERT INTO download_comic (id, title, cover)
            VALUES (?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              title = excluded.title,
              cover = excluded.cover
          ''',
          [task.comic.id, task.comic.title, task.comic.cover],
        );

        await tx.executeBatch(
          '''
            INSERT INTO download_chapter (id, title, chapter_order, task_id)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              title = excluded.title,
              chapter_order = excluded.chapter_order,
              task_id = excluded.task_id
          ''',
          task.chapters.map((chapter) {
            return [chapter.id, chapter.title, chapter.order, task.comic.id];
          }).toList(),
        );

        await tx.executeBatch(
          '''
            INSERT INTO chapter_image (file_server, path, original_name, chapter_id)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(file_server, path) DO UPDATE SET
              original_name = excluded.original_name,
              chapter_id = excluded.chapter_id
          ''',
          task.chapters.expand((chapter) {
            return chapter.images.map((image) {
              return [
                image.fileServer,
                image.path,
                image.originalName,
                chapter.id,
              ];
            });
          }).toList(),
        );
      }
    });
  }

  Future<List<ComicDownloadTask>> getAll() async {
    return await _db.readTransaction((tx) async {
      final taskRows = await tx.getAll('''
        SELECT 
          t.id,
          t.total,
          t.completed,
          t.status,
          c.title,
          c.cover
        FROM download_task t
        JOIN download_comic c ON t.id = c.id
        ORDER BY t.created_at ASC
      ''');

      if (taskRows.isEmpty) return [];

      final tasks = <String, ComicDownloadTask>{};

      for (final row in taskRows) {
        final taskId = row['id'];

        tasks[taskId] =
            ComicDownloadTask(
                comic: DownloadComic(
                  id: taskId,
                  title: row['title'],
                  cover: row['cover'],
                ),
                chapters: [],
              )
              ..total = row['total']
              ..completed = row['completed']
              ..status = DownloadTaskStatus.fromName(row['status']);
      }

      // 2 查询章节
      final chapterRows = await tx.getAll('''
        SELECT id, title, chapter_order, task_id
        FROM download_chapter
        ORDER BY chapter_order ASC
      ''');

      final chapters = <String, DownloadChapter>{};

      for (final row in chapterRows) {
        final chapter = DownloadChapter(
          id: row['id'],
          title: row['title'],
          order: row['chapter_order'],
        );

        chapters[row['id']] = chapter;

        final task = tasks[row['task_id']];
        task?.chapters.add(chapter);
      }

      // 3 查询图片
      final imageRows = await tx.getAll('''
        SELECT file_server, path, original_name, chapter_id
        FROM chapter_image
        ORDER BY id ASC
      ''');

      for (final row in imageRows) {
        final chapter = chapters[row['chapter_id']];
        if (chapter == null) continue;

        chapter.images.add(
          ImageDetail(
            fileServer: row['file_server'],
            path: row['path'],
            originalName: row['original_name'],
          ),
        );
      }

      return tasks.values.toList();
    });
  }

  /// 批量移除下载任务
  Future<void> deleteBatch(List<String> ids) async {
    final params = ids.map((id) => [id]).toList();
    await _db.writeTransaction((tx) async {
      await tx.executeBatch('DELETE FROM download_task WHERE id = ?', params);
    });
  }

  /// 根据comicId查询下载章节
  Future<List<DownloadChapter>> getDownloadChapters(String id) async {
    final result = await _db.readTransaction((tx) async {
      return await tx.getAll(
        'SELECT id, title, chapter_order FROM download_chapter WHERE task_id = ?',
        [id],
      );
    });
    return result.map((row) {
      return DownloadChapter(
        id: row['id'],
        title: row['title'],
        order: row['chapter_order'],
      );
    }).toList();
  }

  Future<DownloadComic> getDownloadComic(String id) async {
    final result = await _db.get(
      'SELECT id, title, cover FROM download_comic WHERE id = ?',
      [id],
    );
    return DownloadComic.fromJson(result);
  }
}
