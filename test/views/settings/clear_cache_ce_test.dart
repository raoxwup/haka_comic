import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clear cache only touches the cached_network_image_ce cache folder', () {
    final source = File(
      'lib/views/settings/clear_cache.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        "const _cachedNetworkImageCeCacheFolderName = 'cached_network_image_ce'",
      ),
    );
    expect(source, contains("const _cachedNetworkImageCeHiveName = 'hive'"));
    expect(
      source,
      contains('p.basename(item.path) == _cachedNetworkImageCeHiveName'),
    );
    expect(
      source,
      isNot(contains("package:extended_image/extended_image.dart")),
    );
    expect(source, isNot(contains('cacheImageFolderName')));
  });
}
