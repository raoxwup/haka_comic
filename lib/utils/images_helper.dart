import 'package:haka_comic/config/setup_config.dart';
import 'package:sqlite_async/sqlite_async.dart';

class ImagesHelper {
  static final ImagesHelper _instance = ImagesHelper._internal();

  factory ImagesHelper() => _instance;

  static ImagesHelper get instance => _instance;

  late SqliteDatabase _db;
  String get dbPath => '${SetupConf.instance.dataPath}/images.db';

  ImagesHelper._internal();

  Future<void> initialize() async {
    _db = SqliteDatabase(path: dbPath);
    await _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS images (
        id INTEGER PRIMARY KEY,
        cid TEXT NOT NULL,
        image_id TEXT NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        UNIQUE(cid, image_id)
      )
    ''');

    await _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_images_cid_image_id
      ON images (cid, image_id);
    ''');
  }

  Future<void> insert(ImageSize imageSize) async {
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

  Future<List<ImageSize>> query(String cid) async {
    final result = await _db.getAll('SELECT * FROM images WHERE cid = ?', [
      cid,
    ]);
    return result.map((row) => ImageSize.fromJson(row)).toList();
  }

  Future<ImageSize?> find(String cid, String imageId) async {
    final result = await _db.get(
      'SELECT * FROM images WHERE cid = ? AND image_id = ?',
      [cid, imageId],
    );
    if (result.isEmpty) return null;
    return ImageSize.fromJson(result);
  }

  Future<void> trim() async {
    await _db.execute(
      'DELETE FROM images WHERE id IN (SELECT id FROM images ORDER BY id ASC LIMIT 3000)',
    );
  }

  Future<void> clear() async {
    await _db.execute('DELETE FROM images');
  }

  Future<void> close() async {
    await _db.close();
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
