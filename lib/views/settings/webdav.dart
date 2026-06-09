import 'dart:io' show File, Directory;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/utils/backup_utils.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' hide File;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

enum ActionType { upload, download }

class WebDAV extends StatefulWidget {
  const WebDAV({super.key});

  @override
  State<WebDAV> createState() => _WebDAVState();
}

class _WebDAVState extends State<WebDAV> {
  final appConf = AppConf();
  late final _urlController = TextEditingController()..text = appConf.webdavUrl;
  late final _usernameController = TextEditingController()
    ..text = appConf.webdavUser;
  late final _passwordController = TextEditingController()
    ..text = appConf.webdavPassword;
  late final _urlFocusNode = FocusNode();
  late final _usernameFocusNode = FocusNode();
  late final _passwordFocusNode = FocusNode();
  ActionType _actionType = ActionType.upload;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _urlFocusNode.addListener(_onUrlFocusChange);
    _usernameFocusNode.addListener(_onUsernameFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  void _onUrlFocusChange() {
    if (!_urlFocusNode.hasFocus) save();
  }

  void _onUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus) save();
  }

  void _onPasswordFocusChange() {
    if (!_passwordFocusNode.hasFocus) save();
  }

  @override
  void dispose() {
    _urlFocusNode.removeListener(_onUrlFocusChange);
    _usernameFocusNode.removeListener(_onUsernameFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _urlFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void connectWebDAV() async {
    const baseDir = '/HaKa Comic';
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      Toast.show(message: '请填写完整信息');
      return;
    }

    final client = newClient(
      url,
      user: username,
      password: password,
      debug: kDebugMode,
    )..setHeaders({"Content-Type": "application/octet-stream"});

    setState(() {
      _loading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final list = await client.readDir('/');
      if (_actionType == ActionType.upload) {
        await performBackup();

        final zipFile = await makeBackupZip();

        await client.writeFromFile(zipFile.path, '$baseDir/$backupFileName');

        if (await zipFile.exists()) {
          await zipFile.delete();
        }

        Toast.show(message: '上传成功');
      } else if (_actionType == ActionType.download) {
        if (!list.any((item) => item.name == 'HaKa Comic')) {
          Toast.show(message: '远程目录不存在');
          return;
        }

        // 使用 restoreFromZip 内部不同的目录名，避免冲突
        final downloadDir = Directory(p.join(tempDir.path, 'webdav_download'));
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        final downloadedZip = File(p.join(downloadDir.path, backupFileName));
        await client.read2File('$baseDir/$backupFileName', downloadedZip.path);

        await restoreFromZip(downloadedZip);

        if (mounted) {
          context.read<BlockProvider>().syncFromDb();
        }

        Toast.show(message: '下载成功');
      }

      save();
    } catch (e) {
      Log.e('WebDAV error', error: e);
      showSnackBar('发生错误: ${e.toString()}');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void save() {
    appConf.webdavUrl = _urlController.text.trim();
    appConf.webdavUser = _usernameController.text.trim();
    appConf.webdavPassword = _passwordController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: '例如：https://example.com/webdav',
                  border: OutlineInputBorder(),
                ),
                controller: _urlController,
                focusNode: _urlFocusNode,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
                controller: _usernameController,
                focusNode: _usernameFocusNode,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '密码',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                controller: _passwordController,
                obscureText: _obscurePassword,
                focusNode: _passwordFocusNode,
              ),
              const SizedBox(height: 12),
              RadioGroup(
                groupValue: _actionType,
                onChanged: (value) {
                  setState(() {
                    _actionType = value!;
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('操作'),
                    Radio(value: ActionType.upload),
                    Text('上传'),
                    SizedBox(width: 12),
                    Radio(value: ActionType.download),
                    Text('下载'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Button.filled(
                onPressed: connectWebDAV,
                isLoading: _loading,
                child: const Text('继续'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
