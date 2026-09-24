import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/settings/visible_categories.dart';
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
      'visibleCategories': ['排行榜'],
    });
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'visibleCategories': ['排行榜'],
        });
    SharedPreferencesUtil.prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );
    AppConf().visibleCategories = ['排行榜'];
  });

  testWidgets('visible categories use a responsive grid of tappable tiles', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: VisibleCategories()));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.widgetWithText(InkWell, '排行榜'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, '排行榜'));
    await tester.pump();

    expect(AppConf().visibleCategories, isNot(contains('排行榜')));

    await tester.tap(find.widgetWithText(InkWell, '全彩'));
    await tester.pump();

    expect(AppConf().visibleCategories, contains('全彩'));
  });
}
