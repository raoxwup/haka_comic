import 'dart:io';
import 'package:path/path.dart' as p;

/// 本地漫画支持的图片扩展名。
const imageExts = {'.jpg', '.jpeg', '.png', '.webp'};

bool isImageFile(String path) => imageExts.contains(p.extension(path).toLowerCase());

/// 列出目录下的图片文件，并按文件名自然排序（数字段按数值大小比较）。
Future<List<File>> listImageFiles(Directory directory) async {
  final files = await directory
      .list(followLinks: false)
      .where((entity) => entity is File && isImageFile(entity.path))
      .cast<File>()
      .toList();

  files.sort(compareEntitiesByNaturalName);
  return files;
}

int compareEntitiesByNaturalName(FileSystemEntity a, FileSystemEntity b) {
  return compareNaturally(
    p.basename(a.path).toLowerCase(),
    p.basename(b.path).toLowerCase(),
  );
}

/// 自然排序：把字符串拆成"数字段/非数字段"，数字段按数值比较，其余按字典序。
int compareNaturally(String a, String b) {
  final pattern = RegExp(r'\d+|\D+');
  final aParts = pattern.allMatches(a).map((match) => match[0]!).toList();
  final bParts = pattern.allMatches(b).map((match) => match[0]!).toList();
  final length = aParts.length < bParts.length ? aParts.length : bParts.length;

  for (var index = 0; index < length; index++) {
    final aPart = aParts[index];
    final bPart = bParts[index];
    final aNumber = int.tryParse(aPart);
    final bNumber = int.tryParse(bPart);

    final compare = aNumber != null && bNumber != null
        ? aNumber.compareTo(bNumber)
        : aPart.compareTo(bPart);

    if (compare != 0) {
      return compare;
    }
  }

  return aParts.length.compareTo(bParts.length);
}
