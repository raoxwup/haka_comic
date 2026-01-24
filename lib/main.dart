import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/providers/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/providers/theme_color_provider.dart';
import 'package:haka_comic/providers/theme_mode_provider.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/startup_prepare.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/about/about.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_auth/local_auth.dart';

void main(List<String> args) {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      StartupPrepare.prepare()
          .then(
            (_) => runApp(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
                  ChangeNotifierProvider(create: (_) => ThemeColorProvider()),
                  ChangeNotifierProvider(create: (_) => SearchProvider()),
                  ChangeNotifierProvider(create: (_) => UserProvider()),
                  ChangeNotifierProvider(
                    create: (_) => BlockProvider(),
                    lazy: false,
                  ),
                ],
                child: const App(),
              ),
            ),
          )
          .wait();
    },
    (Object error, StackTrace stackTrace) {
      Log.error('runZonedGuarded', error, stackTrace);
    },
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WindowListener {
  bool isAuthorized = false;
  bool isVerifying = false;

  void auth() async {
    setState(() => isVerifying = true);
    final auth = LocalAuthentication();
    final canCheckBiometrics = await auth.canCheckBiometrics;
    if (!canCheckBiometrics && !await auth.isDeviceSupported()) {
      setState(() => isAuthorized = true);
      return;
    }
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
      );
      setState(() {
        isAuthorized = didAuthenticate;
        isVerifying = false;
      });
    } catch (e) {
      Log.error('LocalAuthentication', e);
      setState(() {
        isAuthorized = false;
        isVerifying = false;
      });
    }
  }

  @override
  initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 清理图片宽高缓存
    ImagesHelper().trim();

    if (AppConf().checkUpdate) {
      checkUpdate();
    }

    if (isDesktop) {
      windowManager.addListener(this);
    }

    if (AppConf().needAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        auth();
      });
    }
  }

  @override
  void dispose() {
    if (isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMoved() => _saveWindowState();
  @override
  void onWindowResized() => _saveWindowState();
  @override
  void onWindowMaximize() => _saveWindowState();
  @override
  void onWindowUnmaximize() => _saveWindowState();
  @override
  void onWindowEnterFullScreen() => _saveWindowState();
  @override
  void onWindowLeaveFullScreen() => _saveWindowState();

  Future<void> _saveWindowState() async {
    if (kDebugMode) return;

    final conf = AppConf();

    final isFullScreen = await windowManager.isFullScreen();
    conf.windowFullscreen = isFullScreen;

    if (!isFullScreen) {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();
      conf.windowX = position.dx;
      conf.windowY = position.dy;
      conf.windowWidth = size.width;
      conf.windowHeight = size.height;
    }
  }

  void checkUpdate() async {
    await Future.delayed(const Duration(seconds: 1));
    final result = await checkIsUpdated();
    if (result) {
      if (mounted) {
        showUpdateDialog();
      }
    }
  }

  ColorScheme _generateColorScheme(
    Color primaryColor, [
    Brightness? brightness,
  ]) {
    final ColorScheme newScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness ?? Brightness.light,
    );

    return newScheme.harmonized();
  }

  ThemeData getTheme(ColorScheme colorScheme, [Brightness? brightness]) =>
      ThemeData(
        colorScheme: colorScheme,
        brightness: brightness,
        fontFamily: '霞鹜文楷',
        fontFamilyFallback: [
          'Segoe UI',
          'PingFang SC',
          'Noto Sans SC',
          'Noto Sans TC',
          'Noto Sans',
          'Microsoft YaHei',
          'Arial',
          'sans-serif',
        ],
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: GoTransitions.fade,
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            TargetPlatform.iOS: GoTransitions.cupertino,
            TargetPlatform.macOS: GoTransitions.fade,
            TargetPlatform.linux: GoTransitions.fade,
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.themeModeSelector((p) => p.themeMode);
    final themeColor = context.themeColorSelector((p) => p.themeColor);
    return DynamicColorBuilder(
      builder: (light, dark) {
        final ColorScheme lightScheme, darkScheme;
        final Color primary;
        if (themeColor.title != 'System' || light == null || dark == null) {
          primary = themeColor.color;
        } else {
          primary = light.primary;
        }
        lightScheme = _generateColorScheme(primary);
        darkScheme = _generateColorScheme(primary, Brightness.dark);
        return MaterialApp.router(
          title: "HaKa Comic",
          routerConfig: appRouter,
          theme: getTheme(lightScheme),
          darkTheme: getTheme(darkScheme, Brightness.dark),
          themeMode: themeMode.mode,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(child: _SystemUiProvider(child!)),
                if (AppConf().needAuth && !isAuthorized)
                  Positioned.fill(
                    child: Material(
                      child: Container(
                        color: context.colorScheme.surface,
                        child: Column(
                          spacing: 20,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '需要进行身份验证以访问应用程序',
                              style: TextStyle(fontSize: 18),
                            ),
                            Button.filled(
                              isLoading: isVerifying,
                              onPressed: auth,
                              child: const Text('验证'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SystemUiProvider extends StatelessWidget {
  const _SystemUiProvider(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var brightness = Theme.brightnessOf(context);
    SystemUiOverlayStyle systemUiStyle;
    if (brightness == Brightness.light) {
      systemUiStyle = SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
    } else {
      systemUiStyle = SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: child,
    );
  }
}
