import 'package:haka_comic/database/utils.dart';
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

class ImagesHelper with DbBackupMixin {
  ImagesHelper._();

  static final _instance = ImagesHelper._();

  factory ImagesHelper() => _instance;

  @override
  String get dbName => 'images.db';

  @override
  Future<void> initialize() async {
    super.initialize();
    await migrations.migrate(db);
  }

  Future<void> insert(ImageSize imageSize) async {
    await db.writeTransaction((tx) async {
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

  Future<List<ImageSize>> query(String cid) async {
    final result = await db.getAll('SELECT * FROM images WHERE cid = ?', [cid]);
    return result.map((row) => ImageSize.fromJson(row)).toList();
  }

  Future<ImageSize?> find(String cid, String imageId) async {
    final result = await db.getOptional(
      'SELECT * FROM images WHERE cid = ? AND image_id = ?',
      [cid, imageId],
    );
    if (result == null) return null;
    return ImageSize.fromJson(result);
  }

  Future<void> trim() async {
    await db.execute('''
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

  Future<void> clear() async {
    await db.execute('DELETE FROM images');
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
