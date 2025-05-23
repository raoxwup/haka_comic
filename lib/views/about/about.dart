import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/button.dart';
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

  @override
  initState() {
    super.initState();
    _getVersion();
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
          Text(
            'Version $version',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Haka Comic是一个免费开源的第三方哔咔漫画客户端',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.circle_notifications_outlined),
            title: const Text('启动时检查更新'),
            trailing: Switch(value: true, onChanged: (value) {}),
          ),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('检查更新'),
            trailing: Button.filled(child: const Text('检查'), onPressed: () {}),
          ),
          ListTile(
            leading: const Icon(Icons.launch),
            title: const Text('Github'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchURL('https://github.com/raoxwup/haka_comic'),
          ),
        ],
      ),
    );
  }
}
