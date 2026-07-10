import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/search/filter_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'blacklist': ['全彩'],
    });
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'blacklist': ['全彩'],
        });
    SharedPreferencesUtil.prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );
    AppConf().blacklist = ['全彩'];
  });

  testWidgets('filter panel excludes blacklisted categories', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilterPanel(
          sortType: ComicSortType.dd,
          categories: const {'全彩', '長篇'},
          onFilter: ({required type, required categories}) {},
        ),
      ),
    );

    expect(find.text('全彩'), findsNothing);
    expect(find.text('長篇'), findsOneWidget);
    expect(find.textContaining('1 个分类'), findsOneWidget);
  });
}
