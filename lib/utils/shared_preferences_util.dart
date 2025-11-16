import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

class SharedPreferencesUtil {
  static late SharedPreferencesWithCache prefsWithCache;

  static Future<SharedPreferencesWithCache> init() async {
    await migratePreferences();
    prefsWithCache = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return prefsWithCache;
  }

  // 迁移旧版 SharedPreferences
  static Future<void> migratePreferences() async {
    const sharedPreferencesOptions = SharedPreferencesOptions();

    final prefs = await SharedPreferences.getInstance();

    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: prefs,
      sharedPreferencesAsyncOptions: sharedPreferencesOptions,
      migrationCompletedKey: 'migrationCompleted', // 迁移标记键
    );
  }
}
