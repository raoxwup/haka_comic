import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/settings/blacklist.dart';
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

  testWidgets('blacklist uses a responsive grid of tappable category tiles', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Blacklist()));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.widgetWithText(InkWell, '全彩'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, '全彩'));
    await tester.pump();

    expect(AppConf().blacklist, isNot(contains('全彩')));

    await tester.tap(find.widgetWithText(InkWell, '長篇'));
    await tester.pump();

    expect(AppConf().blacklist, contains('長篇'));
  });
}
