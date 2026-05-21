import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/views/download/downloads_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late StreamController<List<ComicDownloadTask>> taskController;
  late StreamController<int> speedController;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testerViewToPhoneSize();
    BackgroundDownloader.dispose();
    taskController = StreamController<List<ComicDownloadTask>>.broadcast();
    speedController = StreamController<int>.broadcast();
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    SharedPreferencesUtil.prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );
  });

  tearDown(() async {
    await taskController.close();
    await speedController.close();
    BackgroundDownloader.dispose();
  });

  testWidgets(
    'downloads default to oldest first and can switch to newest first',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Downloads(
            taskStream: taskController.stream,
            speedStream: speedController.stream,
            onRequestTasks: () {},
          ),
        ),
      );

      taskController.add([
        _task(id: 'old', title: '旧任务'),
        _task(id: 'new', title: '新任务'),
      ]);
      await tester.pump();

      expect(_titleY(tester, '旧任务'), lessThan(_titleY(tester, '新任务')));

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .ancestor(
              of: find.text('新到旧'),
              matching: find.byWidgetPredicate(
                (widget) => widget is PopupMenuItem,
              ),
            )
            .last,
      );
      await tester.pumpAndSettle();

      expect(_titleY(tester, '新任务'), lessThan(_titleY(tester, '旧任务')));
      expect(
        SharedPreferencesUtil.prefsWithCache.getString('downloadTaskSortOrder'),
        'newestFirst',
      );
    },
  );

  testWidgets('downloads restore the saved newest-first sort order', (
    tester,
  ) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'downloadTaskSortOrder': 'newestFirst',
    });
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'downloadTaskSortOrder': 'newestFirst',
        });
    SharedPreferencesUtil.prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );

    await tester.pumpWidget(
      MaterialApp(
        home: Downloads(
          taskStream: taskController.stream,
          speedStream: speedController.stream,
          onRequestTasks: () {},
        ),
      ),
    );

    taskController.add([
      _task(id: 'old', title: '旧任务'),
      _task(id: 'new', title: '新任务'),
    ]);
    await tester.pump();

    expect(_titleY(tester, '新任务'), lessThan(_titleY(tester, '旧任务')));
  });
}

ComicDownloadTask _task({required String id, required String title}) {
  return ComicDownloadTask(
      comic: DownloadComic(id: id, title: title, cover: 'https://example.com'),
      chapters: [DownloadChapter(id: '${id}_chapter', title: '第1话', order: 1)],
    )
    ..total = 1
    ..completed = 0
    ..status = DownloadTaskStatus.queued;
}

double _titleY(WidgetTester tester, String title) {
  return tester.getTopLeft(find.text(title)).dy;
}

void testerViewToPhoneSize() {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.views.single.physicalSize = const Size(400, 800);
  binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
  addTearDown(() {
    binding.platformDispatcher.views.single.resetPhysicalSize();
    binding.platformDispatcher.views.single.resetDevicePixelRatio();
  });
}
