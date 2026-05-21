import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/views/reader/widgets/reader_image.dart';
import 'package:haka_comic/widgets/retry_for_image.dart';

void main() {
  test('ReaderImage CE uses the cached_network_image_ce provider', () {
    final source = File(
      'lib/views/reader/widgets/reader_image.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("package:cached_network_image_ce/cached_network_image.dart"),
    );
    expect(source, contains('CachedNetworkImageProvider('));
    expect(source, isNot(contains('TweenAnimationBuilder')));
    expect(source, isNot(contains('ExtendedImage.network')));
  });

  test('reader preloader uses the same CE network provider', () {
    final source = File(
      'lib/views/reader/utils/image_preload_controller.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("package:cached_network_image_ce/cached_network_image.dart"),
    );
    expect(source, contains('CachedNetworkImageProvider(url)'));
    expect(source, isNot(contains('ExtendedNetworkImageProvider')));
  });

  test('horizontal reader pages use the CE network provider', () {
    final source = File(
      'lib/views/reader/widgets/horizontal_list/horizontal_list.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("package:cached_network_image_ce/cached_network_image.dart"),
    );
    expect(source, contains('CachedNetworkImageProvider('));
    expect(source, contains('item.url'));
    // 单页分支必须显式传入共享的 cacheManager，
    // 否则会与默认 cacheManager 抢同一个 Hive box 引发互相清缓存。
    expect(source, contains('cacheManager: cacheManager'));
    expect(source, contains('CachedNetworkImage.evictFromCache(item.url)'));
    expect(source, isNot(contains('ExtendedNetworkImageProvider')));
    expect(source, isNot(contains('clearMemoryImageCache')));
  });

  test('horizontal reader avoids duplicate image size writes', () {
    final source = File(
      'lib/views/reader/widgets/horizontal_list/horizontal_list.dart',
    ).readAsStringSync();

    expect(source, contains('final Set<String> _reportedImageSizeIds = {};'));
    expect(source, contains('bool _reportImageSizeOnce('));
    expect(source, contains('_reportImageSizeOnce('));
  });

  test('vertical reader decodes with double-tap zoom clarity headroom', () {
    final source = File(
      'lib/views/reader/widgets/vertical_list/vertical_list.dart',
    ).readAsStringSync();

    expect(source, contains('static const double _zoomClarityScale = 3.0'));
    expect(source, contains('MediaQuery.devicePixelRatioOf(context)'));
    expect(source, contains('cacheWidth: cacheWidth'));
  });

  testWidgets('network ReaderImage keeps the cached aspect placeholder', (
    tester,
  ) async {
    final imageSize = ImageSize(
      width: 300,
      height: 600,
      imageId: 'page-1',
      cid: 'chapter-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReaderImage(
          url: 'https://example.invalid/page-1.jpg',
          imageSize: imageSize,
          filterQuality: FilterQuality.high,
          onImageSizeChanged: (_, _) {},
        ),
      ),
    );

    final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(aspectRatio.aspectRatio, 0.5);
  });

  testWidgets('network ReaderImage applies the requested memory cache width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderImage(
          url: 'https://example.invalid/page-1.jpg',
          cacheWidth: 2160,
          onImageSizeChanged: (_, _) {},
        ),
      ),
    );

    final retryForImage = tester.widget<RetryForImage>(
      find.byType(RetryForImage),
    );
    final provider = retryForImage.imageProvider;
    expect(provider, isA<ResizeImage>());
    final resize = provider as ResizeImage;
    expect(resize.width, 2160);
    expect(resize.imageProvider, isA<CachedNetworkImageProvider>());
  });

  testWidgets('local ReaderImage applies the requested image cache width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderImage(
          url: 'C:/missing/page-1.jpg',
          cacheWidth: 2160,
          onImageSizeChanged: (_, _) {},
        ),
      ),
    );

    final retryForImage = tester.widget<RetryForImage>(
      find.byType(RetryForImage),
    );
    final provider = retryForImage.imageProvider;
    expect(provider, isA<ResizeImage>());
    final resize = provider as ResizeImage;
    expect(resize.width, 2160);
    expect(resize.imageProvider, isA<FileImage>());
  });

  testWidgets('local ReaderImage automatically retries failed loads twice', (
    tester,
  ) async {
    final missingPath =
        '${Directory.systemTemp.path}/haka_comic_missing_reader_image.jpg';

    const retryDelay = Duration(milliseconds: 50);
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderImage(
          url: missingPath,
          timeRetry: retryDelay,
          onImageSizeChanged: (_, _) {},
        ),
      ),
    );

    // Alternate a real-time delay (so the FileImage IO can fail) with a
    // fake-clock advance past the retry delay (so the internal timer fires).
    Future<void> advanceOneCycle() async {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(retryDelay + const Duration(milliseconds: 10));
    }

    for (
      var i = 0;
      i < 10 && find.byIcon(Icons.refresh).evaluate().isEmpty;
      i++
    ) {
      await advanceOneCycle();
    }

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    // Advance past the fade-out so the outgoing loading child is gone.
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
