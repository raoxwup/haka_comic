import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/config/setup_config.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> with AutoRegisterHandlerMixin {
  String version = '';
  bool _checkUpdate = AppConf().checkUpdate;
  late final _handler = checkIsUpdated.useRequest(
    onSuccess: (shouldCheckUpdate, _) {
      if (shouldCheckUpdate) {
        showUpdateDialog();
      } else {
        Toast.show(message: '当前已是最新版本');
      }
    },
    onError: (error, _) {
      Log.error('fetch release error', error);
      Toast.show(message: '获取版本信息失败');
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  initState() {
    super.initState();
    _handler.isLoading = false;
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      Toast.show(message: '无法打开链接');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints.tight(const Size(120, 120)),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  isDarkMode
                      ? 'assets/icons/ios/Dark.png'
                      : 'assets/icons/ios/Light.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Version ${SetupConf.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'HaKa Comic是一个开源免费的第三方哔咔漫画客户端',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('启动时检查更新'),
            value: _checkUpdate,
            onChanged: (value) {
              setState(() {
                _checkUpdate = value;
                AppConf().checkUpdate = value;
              });
            },
          ),
          ListTile(
            title: const Text('检查更新'),
            trailing: _handler.isLoading
                ? CircularProgressIndicator(
                    constraints: BoxConstraints.tight(const Size(16, 16)),
                    strokeWidth: 2,
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: () => _handler.run(),
          ),
          ListTile(
            title: const Text('Github'),
            trailing: const Icon(Icons.launch),
            onTap: () => _launchURL('https://github.com/raoxwup/haka_comic'),
          ),
        ],
      ),
    );
  }
}

void showUpdateDialog() {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => AlertDialog(
      title: const Text('更新'),
      content: const Text('有新版本可用，是否前往下载?'),
      actions: [
        TextButton(child: const Text('取消'), onPressed: () => context.pop()),
        TextButton(
          child: const Text('前往'),
          onPressed: () => launchUrl(
            Uri.parse('https://github.com/raoxwup/haka_comic/releases'),
          ),
        ),
      ],
    ),
  );
}
