import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String version = '';
  bool _checkUpdate = AppConf().checkUpdate;
  late final _handler = fetchLatestRelease.useRequest(
    onSuccess: (data, _) {
      final latestReleaseVersion = data["tag_name"] as String;
      // 目前先简单判断版本号是否一致
      if (latestReleaseVersion != version) {
        Toast.show(message: '有新版本可用');
      } else {
        Toast.show(message: '当前已是最新版本');
      }
    },
    onError: (error, _) {
      Log.error('fetch release error', error);
      Toast.show(message: '获取版本信息失败');
    },
  );

  void update() => setState(() {});

  @override
  initState() {
    super.initState();
    _getVersion();
    _handler
      ..addListener(update)
      ..isLoading = false;
  }

  @override
  dispose() {
    _handler
      ..removeListener(update)
      ..dispose();
    super.dispose();
  }

  Future<void> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
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
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(
              isDarkMode
                  ? 'assets/icons/ios/Dark.png'
                  : 'assets/icons/ios/Light.png',
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(height: 5),
          Text('Version $version', textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(
            'Haka Comic是一个开源免费的第三方哔咔漫画客户端',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('启动时检查更新'),
            trailing: Switch(
              value: _checkUpdate,
              onChanged: (value) {
                setState(() {
                  _checkUpdate = value;
                  AppConf().checkUpdate = value;
                });
              },
            ),
          ),
          ListTile(
            title: const Text('检查更新'),
            trailing:
                _handler.isLoading
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
