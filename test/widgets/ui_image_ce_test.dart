import 'dart:async';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/router/route_observer.dart';
import 'package:haka_comic/widgets/retry_for_image.dart';
import 'package:haka_comic/widgets/ui_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UiImage CE uses the cached_network_image_ce provider', () {
    final source = File('lib/widgets/ui_image.dart').readAsStringSync();

    expect(source, isNot(contains('TweenAnimationBuilder')));
    expect(source, isNot(contains('fadeInDuration: Duration.zero')));
    expect(
      source,
      contains("package:cached_network_image_ce/cached_network_image.dart"),
    );
    expect(source, contains('CachedNetworkImageProvider('));
  });

  testWidgets(
    'UiImage CE exposes the UiImage constructor and initial placeholder',
    (tester) async {
      const placeholderKey = Key('ui-image-ce-placeholder');

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: Material(
            child: UiImage(
              url: 'https://example.invalid/image.png',
              fit: BoxFit.contain,
              width: 120,
              height: 80,
              cacheWidth: 240,
              cacheHeight: 160,
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.red),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              clipBehavior: Clip.hardEdge,
              filterQuality: FilterQuality.medium,
              placeholder: const SizedBox(
                key: placeholderKey,
                width: 120,
                height: 80,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(placeholderKey), findsOneWidget);
    },
  );

  testWidgets('UiImage CE frames the retry-aware image from the outside', (
    tester,
  ) async {
    final border = Border.all(color: Colors.blue);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [routeObserver],
        home: Material(
          child: UiImage(
            url: 'https://example.invalid/framed-image.png',
            fit: BoxFit.contain,
            width: 120,
            height: 80,
            cacheWidth: 240,
            cacheHeight: 160,
            shape: BoxShape.rectangle,
            border: border,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            clipBehavior: Clip.hardEdge,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );

    await tester.pump();
    final expectedMemCacheWidth = (120 * tester.view.devicePixelRatio).round();

    final retryFinder = find.byType(RetryForImage);
    expect(retryFinder, findsOneWidget);

    final frameFinder = find.ancestor(
      of: retryFinder,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container) return false;

        final constraints = widget.constraints;
        final decoration = widget.decoration;

        return widget.clipBehavior == Clip.hardEdge &&
            constraints?.minWidth == 120 &&
            constraints?.maxWidth == 120 &&
            constraints?.minHeight == 80 &&
            constraints?.maxHeight == 80 &&
            decoration is BoxDecoration &&
            decoration.color != null &&
            decoration.shape == BoxShape.rectangle &&
            decoration.border == border &&
            decoration.borderRadius ==
                const BorderRadius.all(Radius.circular(8));
      }),
    );
    expect(frameFinder, findsOneWidget);

    final retryForImage = tester.widget<RetryForImage>(retryFinder);
    final provider = retryForImage.imageProvider;
    expect(provider, isA<ResizeImage>());
    final resize = provider as ResizeImage;
    expect(resize.width, expectedMemCacheWidth);
    expect(resize.height, 160);
    expect(resize.imageProvider, isA<CachedNetworkImageProvider>());
  });

  testWidgets(
    'UiImage automatically retries failed loads and hides refresh until exhausted',
    (tester) async {
      final originalCacheManager =
          CachedNetworkImageProvider.defaultCacheManager;
      CachedNetworkImageProvider.defaultCacheManager = _FailingCacheManager();
      addTearDown(() {
        CachedNetworkImageProvider.defaultCacheManager = originalCacheManager;
      });

      const retryDelay = Duration(milliseconds: 50);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: const Material(
            child: UiImage(
              url: 'https://example.invalid/ui-image.png',
              width: 120,
              height: 80,
              timeRetry: retryDelay,
            ),
          ),
        ),
      );

      // Each retry cycle is: let the provider's async IO fail (via
      // `runAsync`), pump to flush the error into state, then advance the
      // fake clock past `retryDelay` so the retry timer fires.
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

      // Once exhausted, further wall-clock and fake-clock advances don't
      // schedule more auto retries.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    },
  );

  testWidgets(
    'UiImage does not reacquire pool slots after a dialog is closed',
    (tester) async {
      final originalCacheManager =
          CachedNetworkImageProvider.defaultCacheManager;
      final cacheManager = _PendingCacheManager();
      CachedNetworkImageProvider.defaultCacheManager = cacheManager;
      addTearDown(() async {
        CachedNetworkImageProvider.defaultCacheManager = originalCacheManager;
        await cacheManager.close();
      });

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: const _UiImagePoolHost(),
        ),
      );
      await tester.pump();
      await tester.pump();

      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('placeholder-$i')), findsNothing);
      }

      final hostState = tester.state<_UiImagePoolHostState>(
        find.byType(_UiImagePoolHost),
      );
      hostState.showCoveringDialog();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('close-dialog')));
      await tester.pumpAndSettle();

      hostState.addImage();
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('placeholder-6')), findsNothing);
    },
  );
}

class _UiImagePoolHost extends StatefulWidget {
  const _UiImagePoolHost();

  @override
  State<_UiImagePoolHost> createState() => _UiImagePoolHostState();
}

class _UiImagePoolHostState extends State<_UiImagePoolHost> {
  int count = 6;

  void addImage() {
    setState(() => count++);
  }

  void showCoveringDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            key: const Key('close-dialog'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Wrap(
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(
              width: 24,
              height: 24,
              child: UiImage(
                url: 'https://example.invalid/$i.png',
                width: 24,
                height: 24,
                placeholder: SizedBox(key: ValueKey('placeholder-$i')),
              ),
            ),
        ],
      ),
    );
  }
}

class _FailingCacheManager extends DefaultCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    if (withProgress) {
      yield DownloadProgress(url, null, 0);
    }
    throw Exception('forced image failure');
  }

  @override
  Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) {
    return getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: withProgress,
    );
  }
}

class _PendingCacheManager extends DefaultCacheManager {
  final List<StreamController<FileResponse>> _controllers = [];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    final controller = StreamController<FileResponse>();
    _controllers.add(controller);
    return controller.stream;
  }

  @override
  Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) {
    return getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: withProgress,
    );
  }

  Future<void> close() async {
    await Future.wait([
      for (final controller in _controllers)
        if (!controller.isClosed) controller.close(),
    ]);
  }
}
