import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/images_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart';
import 'package:path/path.dart' as p;

enum ActionType { upload, download }

class WebDAV extends StatefulWidget {
  const WebDAV({super.key});

  @override
  State<WebDAV> createState() => _WebDAVState();
}

class _WebDAVState extends State<WebDAV> {
  final appConf = AppConf();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  ActionType _actionType = ActionType.upload;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _urlController.text = appConf.webdavUrl;
    _usernameController.text = appConf.webdavUser;
    _passwordController.text = appConf.webdavPassword;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  /// Connect to WebDAV server and perform upload or download
  void connectWebDAV() async {
    const baseDir = '/HaKa Comic';
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      Toast.show(message: '请填写完整信息');
      return;
    }

    var client = newClient(
      url,
      user: username,
      password: password,
      debug: kDebugMode,
    )..setHeaders({"Content-Type": "application/octet-stream"});

    setState(() {
      _loading = true;
    });

    try {
      final list = await client.readDir('/');
      if (_actionType == ActionType.upload) {
        if (list.any((item) => item.name == 'HaKa Comic')) {
          await client.remove('/HaKa Comic/');
        }
        final files = await Future.wait([
          ImagesHelper.backup(),
          HistoryHelper().backup(),
          ReadRecordHelper().backup(),
        ]);
        await Future.wait(
          files.map((file) {
            final fileName = p.basename(file.path);
            return client.writeFromFile(file.path, '$baseDir/$fileName');
          }),
        );
        for (var file in files) {
          if (await file.exists()) {
            await file.delete();
          }
        }
        Toast.show(message: '上传成功');
      } else if (_actionType == ActionType.download) {
        if (!list.any((item) => item.name == 'HaKa Comic')) {
          Toast.show(message: '远程目录不存在');
          return;
        }
        final names = {'images.db', 'history.db', 'read_record.db'};
        final files = await client.readDir(baseDir);
        if (!files.map((f) => f.name).toSet().containsAll(names)) {
          Toast.show(message: '远程目录不完整');
          return;
        }
        final tempDir = await getTemporaryDirectory();
        await Future.wait(
          names.map((name) {
            final path = '${tempDir.path}/$name';
            return client.read2File('$baseDir/$name', path);
          }),
        );
        final imagesDB = io.File('${tempDir.path}/images.db');
        final historyDB = io.File('${tempDir.path}/history.db');
        final readRecordDB = io.File('${tempDir.path}/read_record.db');
        await Future.wait([
          ImagesHelper.restore(imagesDB),
          HistoryHelper().restore(historyDB),
          ReadRecordHelper().restore(readRecordDB),
        ]);
        Toast.show(message: '下载成功');
      }

      save();
    } catch (e) {
      Log.error('WebDAV error', e);
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
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
                controller: _usernameController,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
                controller: _passwordController,
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
