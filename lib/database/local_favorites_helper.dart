import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haka_comic/database/utils.dart';
import 'package:haka_comic/network/models.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations = SqliteMigrations()
  ..add(
    SqliteMigration(1, (tx) async {
      // 文件夹表
      await tx.execute('''
          CREATE TABLE IF NOT EXISTS local_folders (
            id INTEGER PRIMARY KEY,
            name TEXT UNIQUE NOT NULL,
            parent_id INTEGER, -- 保留字段：目前业务层默认为 NULL，支持未来扩展为树形结构
            sort_order REAL DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (parent_id) REFERENCES local_folders(id)
              ON DELETE CASCADE
              ON UPDATE CASCADE
          );
        ''');

      await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_local_folders_parent_id 
          ON local_folders(parent_id)
        ''');

      await tx.execute('''
          CREATE TRIGGER IF NOT EXISTS update_local_folders_timestamp 
            AFTER UPDATE ON local_folders 
            BEGIN
                UPDATE local_folders SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
            END;
        ''');

      // 漫画表
      await tx.execute('''
          CREATE TABLE IF NOT EXISTS local_favorite_comics (
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
            tags TEXT DEFAULT '[]',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
          );
        ''');

      await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_local_favorite_comics_cid 
          ON local_favorite_comics(cid)
        ''');

      await tx.execute('''
          CREATE TRIGGER IF NOT EXISTS update_local_favorite_comics_timestamp 
            AFTER UPDATE ON local_favorite_comics 
            BEGIN
                UPDATE local_favorite_comics SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
            END;
        ''');

      // 漫画和文件夹关联表
      await tx.execute('''
          CREATE TABLE IF NOT EXISTS local_folder_comic_refs (
            folder_id INTEGER NOT NULL,
            comic_cid TEXT NOT NULL,
            sort_order REAL DEFAULT 0, -- 允许漫画在不同文件夹中有不同的排序
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (folder_id, comic_cid), -- 联合主键防止重复添加
            FOREIGN KEY (folder_id) REFERENCES local_folders(id) ON DELETE CASCADE,
            FOREIGN KEY (comic_cid) REFERENCES local_favorite_comics(cid) ON DELETE CASCADE
          );
        ''');

      await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_refs_comic_id ON local_folder_comic_refs(comic_cid);
        ''');

      await tx.execute('''
          -- 当删除引用表记录后，如果该漫画没有其他引用，则自动删除漫画表记录
          CREATE TRIGGER IF NOT EXISTS cleanup_unused_comics
          AFTER DELETE ON local_folder_comic_refs
          BEGIN
              DELETE FROM local_favorite_comics
              WHERE cid = OLD.comic_cid
              AND NOT EXISTS (SELECT 1 FROM local_folder_comic_refs WHERE comic_cid = OLD.comic_cid);
          END;
        ''');
    }),
  );

class LocalFavoritesHelper with ChangeNotifier, DbBackupMixin {
  LocalFavoritesHelper._();
  static final _instance = LocalFavoritesHelper._();
  factory LocalFavoritesHelper() => _instance;

  @override
  String get dbName => 'local_favorites.db';

  @override
  SqliteDatabase initSqliteDatabase() =>
      SqliteDatabase.withFactory(ForeignKeysOnSqliteOpenFactory(path: dbPath));

  @override
  Future<void> initialize() async {
    super.initialize();
    await migrations.migrate(db);
  }

  /// 新建文件夹 如果name已存在，返回false，如果不存在，新建，返回true
  Future<bool> createFolder(String name) async {
    final conflict = await db.getOptional(
      'SELECT 1 FROM local_folders WHERE name = ? LIMIT 1',
      [name.trim()],
    );
    if (conflict != null) {
      return false;
    }

    // 默认插入到末尾，避免 sort_order 全为 0 导致顺序不稳定
    final nextOrderRow = await db.getOptional(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM local_folders',
    );
    final nextOrder = (nextOrderRow?['next_order'] as num?)?.toDouble() ?? 0.0;

    await db.execute(
      'INSERT OR IGNORE INTO local_folders (name, sort_order) VALUES (?, ?)',
      [name.trim(), nextOrder],
    );
    return true;
  }

  // 删除文件夹
  Future<void> deleteFolder(int id) async {
    await db.execute('DELETE FROM local_folders WHERE id = ?', [id]);
  }

  // 修改文件夹名称
  Future<void> renameFolder(RenameFolderPayload payload) async {
    await db.execute(
      'UPDATE OR IGNORE local_folders SET name = ? WHERE id = ?',
      [payload.name.trim(), payload.id],
    );
  }

  // 更新文件夹的排序（按传入顺序从 0 开始重排）
  Future<void> updateFolderOrder(List<int> orderedFolderIds) async {
    if (orderedFolderIds.isEmpty) return;
    await db.writeTransaction((tx) async {
      await tx.executeBatch(
        'UPDATE local_folders SET sort_order = ? WHERE id = ?',
        orderedFolderIds
            .asMap()
            .entries
            .map((e) => [e.key.toDouble(), e.value])
            .toList(),
      );
    });
  }

  // 获取文件夹列表及其漫画数量
  Future<List<LocalFolder>> getFoldersWithCount() async {
    final result = await db.getAll('''
      SELECT f.*, COUNT(r.comic_cid) as comic_count 
      FROM local_folders f
      LEFT JOIN local_folder_comic_refs r ON f.id = r.folder_id
      GROUP BY f.id
      ORDER BY f.sort_order, f.id
    ''');
    return result.isEmpty
        ? []
        : result.map((row) => LocalFolder.fromJson(row)).toList();
  }

  // 获取某个文件夹下的所有漫画,不传id则获取所有
  Future<List<HistoryDoc>> getFolderComics(int? id) async {
    ResultSet result;

    if (id == null) {
      result = await db.getAll(
        'SELECT * FROM local_favorite_comics ORDER BY updated_at DESC',
      );
    } else {
      result = await db.getAll(
        '''
          SELECT c.*
          FROM local_favorite_comics c
          INNER JOIN local_folder_comic_refs r
            ON r.comic_cid = c.cid
          WHERE r.folder_id = ?
          ORDER BY r.created_at DESC
        ''',
        [id],
      );
    }

    return result
        .map(
          (row) => HistoryDoc.fromJson({
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
            "tags": jsonDecode(row["tags"]),
          }),
        )
        .toList();
  }

  // 将漫画添加到文件夹
  Future<void> addComicToFolder({
    required Comic comic,
    required int folderId,
  }) async {
    await db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT INTO local_favorite_comics (
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
          likes_count,
          tags
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
          likes_count = excluded.likes_count,
          tags = excluded.tags
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
          jsonEncode(comic.tags),
        ],
      );

      await tx.execute(
        'INSERT OR IGNORE INTO local_folder_comic_refs (folder_id, comic_cid) VALUES (?, ?)',
        [folderId, comic.id],
      );
    });
  }

  /// 将漫画从文件夹中移除
  Future<void> removeComicFromFolder(String cid, int folderId) async {
    await db.execute(
      'DELETE FROM local_folder_comic_refs WHERE folder_id = ? AND comic_cid = ?',
      [folderId, cid],
    );
  }

  /// 漫画在文件夹中则移除，不在文件夹中则添加
  Future<void> toggleComicInFolder(ToggleComicInFolderPayload payload) async {
    final result = await db.getOptional(
      'SELECT 1 FROM local_folder_comic_refs WHERE folder_id = ? AND comic_cid = ? LIMIT 1',
      [payload.folderId, payload.comic.id],
    );
    if (result != null) {
      await removeComicFromFolder(payload.comic.id, payload.folderId);
    } else {
      await addComicToFolder(comic: payload.comic, folderId: payload.folderId);
    }
  }

  // 获取跟漫画相关的文件夹
  Future<List<LocalFolder>> getComicFolders(String cid) async {
    final result = await db.getAll(
      'SELECT * FROM local_folders WHERE id IN (SELECT folder_id FROM local_folder_comic_refs WHERE comic_cid = ?)',
      [cid],
    );
    return result.isEmpty
        ? []
        : result.map((row) => LocalFolder.fromJson(row)).toList();
  }

  // 获取所有文件夹以及文件夹是否收藏了该漫画
  Future<List<LocalFolderWithFavorited>> getFoldersByComic(String cid) async {
    final result = await db.getAll(
      '''
        SELECT
          f.*,
          COUNT(r.comic_cid) AS comic_count,
          CASE
            WHEN EXISTS (
              SELECT 1
              FROM local_folder_comic_refs x
              WHERE x.folder_id = f.id
                AND x.comic_cid = ?
            )
            THEN 1 ELSE 0
          END AS favorited
        FROM local_folders f
        LEFT JOIN local_folder_comic_refs r
          ON f.id = r.folder_id
        GROUP BY f.id
        ORDER BY f.sort_order, f.id
      ''',
      [cid],
    );

    return result.isEmpty
        ? []
        : result.map((row) => LocalFolderWithFavorited.fromJson(row)).toList();
  }

  // 获取收藏的所有漫画数量
  Future<int> getFavoritedComicCount() async {
    final result = await db.get('SELECT COUNT(*) FROM local_favorite_comics');
    return result['COUNT(*)'] as int;
  }
}

class LocalFolder {
  final int id;
  final String name;
  final double sortOrder;
  final String createdAt;
  final String updatedAt;
  final int comicCount;

  const LocalFolder({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.comicCount,
  });

  factory LocalFolder.fromJson(Map<String, dynamic> json) {
    return LocalFolder(
      id: json['id'] as int,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      comicCount: json['comic_count'] ?? 0,
    );
  }
}

class LocalFolderWithFavorited extends LocalFolder {
  final bool favorited;

  const LocalFolderWithFavorited({
    required super.id,
    required super.comicCount,
    required super.createdAt,
    required super.sortOrder,
    required super.name,
    required super.updatedAt,
    this.favorited = false,
  });

  factory LocalFolderWithFavorited.fromJson(Map<String, dynamic> json) {
    return LocalFolderWithFavorited(
      id: json['id'] as int,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      comicCount: json['comic_count'] ?? 0,
      favorited: json['favorited'] == 1,
    );
  }
}

class RenameFolderPayload {
  final int id;
  final String name;

  const RenameFolderPayload({required this.id, required this.name});
}

class ToggleComicInFolderPayload {
  final Comic comic;
  final int folderId;

  const ToggleComicInFolderPayload({
    required this.comic,
    required this.folderId,
  });
}
