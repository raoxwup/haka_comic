import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';
import 'package:haka_comic/views/settings/api_settings.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({'api': Api.go2778.name});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'api': Api.go2778.name});
    SharedPreferencesUtil.prefsWithCache =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );
    AppConf().api = Api.go2778;
  });

  testWidgets('API settings use settings-style list and show selected API', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ApiSettings()));

    expect(find.byType(Block), findsNWidgets(2));
    expect(find.text('服务器'), findsOneWidget);
    expect(find.text('说明'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(RadioListTile<Api>), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    expect(find.widgetWithText(ListTile, Api.go2778.name), findsOneWidget);
    expect(find.widgetWithText(ListTile, Api.picacomic.name), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, Api.picacomic.name));
    await tester.pump();

    final selectedTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, Api.picacomic.name),
    );
    expect(selectedTile.selected, isTrue);
    expect(AppConf().api, Api.picacomic);
  });
}
