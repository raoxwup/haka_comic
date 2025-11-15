import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:haka_comic/config/setup_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations = SqliteMigrations()
  ..add(
    SqliteMigration(1, (tx) async {
      await tx.execute('''
          CREATE TABLE IF NOT EXISTS images (
            id INTEGER PRIMARY KEY,
            cid TEXT NOT NULL,
            image_id TEXT NOT NULL,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            UNIQUE(cid, image_id)
          )
        ''');

      await tx.execute('''
          CREATE INDEX IF NOT EXISTS idx_images_cid_image_id
          ON images (cid, image_id);
        ''');
    }),
  );

class ImagesHelper {
  static late SqliteDatabase _db;
  static String get dbPath => '${SetupConf.dataPath}/images.db';

  static Future<void> initialize() async {
    _db = SqliteDatabase(path: dbPath);
    await migrations.migrate(_db);
  }

  static Future<void> insert(ImageSize imageSize) async {
    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT INTO images (cid, image_id, width, height)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(cid, image_id) DO UPDATE SET
          width = excluded.width,
          height = excluded.height
        ''',
        [imageSize.cid, imageSize.imageId, imageSize.width, imageSize.height],
      );
    });
  }

  static Future<List<ImageSize>> query(String cid) async {
    final result = await _db.getAll('SELECT * FROM images WHERE cid = ?', [
      cid,
    ]);
    return result.map((row) => ImageSize.fromJson(row)).toList();
  }

  static Future<ImageSize?> find(String cid, String imageId) async {
    final result = await _db.getOptional(
      'SELECT * FROM images WHERE cid = ? AND image_id = ?',
      [cid, imageId],
    );
    if (result == null) return null;
    return ImageSize.fromJson(result);
  }

  static Future<void> trim() async {
    await _db.execute('''
        DELETE FROM images
        WHERE id IN (
          SELECT id FROM images
          ORDER BY id ASC
          LIMIT (
            SELECT MAX(COUNT(*) - 5000, 0) FROM images
          )
        );
      ''');
  }

  static Future<void> clear() async {
    await _db.execute('DELETE FROM images');
  }

  static Future<File> backup() async {
    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, 'images.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await _db.execute('VACUUM INTO ?', [path]);
    return File(path);
  }

  static Future<void> restore(File file) async {
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

class ImageSize {
  final int width;
  final int height;
  final String imageId;
  final String cid;

  ImageSize({
    required this.width,
    required this.height,
    required this.imageId,
    required this.cid,
  });

  factory ImageSize.fromJson(Map<String, dynamic> json) => ImageSize(
    width: json['width'] as int,
    height: json['height'] as int,
    imageId: json['image_id'] as String,
    cid: json['cid'] as String,
  );

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'image_id': imageId,
    'cid': cid,
  };
}
