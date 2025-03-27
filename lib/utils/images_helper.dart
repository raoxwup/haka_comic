// import 'package:haka_comic/config/setup_config.dart';
// import 'package:haka_comic/utils/log.dart';
// import 'package:sqlite3/sqlite3.dart';

// class ImagesHelper {
//   static ImagesHelper instance = ImagesHelper._internal();

//   factory ImagesHelper() => instance;

//   late Database _db;

//   String get dbPath => '${SetupConf.instance.dataPath}/images.db';

//   ImagesHelper._internal() {
//     _db = sqlite3.open(dbPath);

//     _db.execute('''
//       CREATE TABLE IF NOT EXISTS images (
//         id INTEGER PRIMARY KEY,
//         cid TEXT NOT NULL,
//         image_id TEXT NOT NULL,
//         width REAL NOT NULL,
//         height REAL NOT NULL,
//         UNIQUE(cid, image_id)
//       )
//     ''');

//     _db.execute('''
//       CREATE INDEX IF NOT EXISTS idx_images_cid_image_id
//       ON images (cid, image_id);
//     ''');
//   }

//   void insert(List<ImageSize> imageSizes) {
//     _db.execute('BEGIN TRANSACTION');
//     final PreparedStatement stmt = _db.prepare('''
//         INSERT INTO images (cid, image_id, width, height)
//         VALUES (?, ?, ?, ?)
//         ON CONFLICT(cid, image_id) DO UPDATE SET
//           width = excluded.width,
//           height = excluded.height
//       ''');
//     try {
//       for (final imageSize in imageSizes) {
//         stmt.execute([
//           imageSize.cid,
//           imageSize.imageId,
//           imageSize.width,
//           imageSize.height,
//         ]);
//       }
//       _db.execute('COMMIT');
//       print("insert images success");
//     } catch (e) {
//       Log.error('insert images error', e);
//       _db.execute('ROLLBACK');
//       rethrow;
//     } finally {
//       stmt.dispose();
//     }
//   }

//   List<ImageSize> query(String cid) {
//     final result = _db.select('SELECT * FROM images WHERE cid = ?', [cid]);
//     return result.map((row) => ImageSize.fromJson(row)).toList();
//   }

//   ImageSize? find(String cid, String imageId) {
//     final result = _db.select(
//       'SELECT * FROM images WHERE cid = ? AND image_id = ?',
//       [cid, imageId],
//     );
//     if (result.isEmpty) return null;
//     return ImageSize.fromJson(result.first);
//   }

//   void clear() => _db.execute('DELETE FROM images');

//   void close() => _db.dispose();
// }

// class ImageSize {
//   final double width;
//   final double height;
//   final String imageId;
//   final String cid;

//   ImageSize({
//     required this.width,
//     required this.height,
//     required this.imageId,
//     required this.cid,
//   });

//   factory ImageSize.fromJson(Map<String, dynamic> json) => ImageSize(
//     width: json['width'] as double,
//     height: json['height'] as double,
//     imageId: json['image_id'] as String,
//     cid: json['cid'] as String,
//   );

//   Map<String, dynamic> toJson() => {
//     'width': width,
//     'height': height,
//     'image_id': imageId,
//     'cid': cid,
//   };
// }
