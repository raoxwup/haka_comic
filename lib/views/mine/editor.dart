import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart'
    hide UseRequest1Extensions, AsyncRequestHandler;
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/toast.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> with RequestMixin {
  @override
  registerHandler() => [_avatarUpdateHandler, _sloganUpdateHandler];

  late final _avatarUpdateHandler = updateAvatar.useRequest(
    manual: true,
    onSuccess: (data, _) {
      Toast.show(message: '头像更新成功');
      Log.info('Update avatar success', 'avatar');
      context.userReader.userHandler.refresh();
    },
    onError: (e, _) {
      Toast.show(message: '头像更新失败');
      Log.error('Update avatar error', e);
    },
  );

  late final _sloganUpdateHandler = updateProfile.useRequest(
    manual: true,
    onSuccess: (data, _) {
      Toast.show(message: '自我介绍更新成功');
      Log.info('Update slogan success', 'slogan');
      context.userReader.userHandler.refresh();
    },
    onError: (e, _) {
      Toast.show(message: '自我介绍更新失败');
      Log.error('Update slogan error', e);
    },
  );

  Future<void> _pickImage() async {
    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (pickedFile != null) {
        if (pickedFile.files.single.size > 5 * 1024 * 1024) {
          Toast.show(message: '图片不能大于5MB');
          return;
        }
        // 读取文件字节
        final bytes = await File(pickedFile.files.single.path!).readAsBytes();
        // 转换为 Base64
        final base64 = base64Encode(bytes);
        await _avatarUpdateHandler.run(base64);
      }
    } catch (e) {
      Log.error("Error picking image", e);
      Toast.show(message: '选择图片失败');
    }
  }

  void showSloganEditor() async {
    String slogan = '';
    await showDialog(
      context: context,
      builder: (context) {
        var controller = TextEditingController();
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(20),
          title: const Text('编辑'),
          children: [
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (s) {
                slogan = s;
                context.pop();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    slogan = controller.text;
                    context.pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (slogan.isNotEmpty) {
      _sloganUpdateHandler.run(slogan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = context.userWatcher.userHandler;
    final value = handler.state.data!.user;
    return Scaffold(
      appBar: AppBar(title: const Text('编辑')),
      body: Stack(
        children: [
          if (handler.state.loading ||
              _avatarUpdateHandler.state.loading ||
              _sloganUpdateHandler.state.loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          ListView(
            children: [
              ListItem(
                onTap: _pickImage,
                title: Text('头像', style: context.textTheme.titleMedium),
                trailing: BaseImage(
                  url: value.avatar?.url ?? '',
                  width: 64,
                  height: 64,
                  shape: const CircleBorder(),
                ),
              ),
              ListItem(
                title: Text('昵称', style: context.textTheme.titleMedium),
                trailing: Text(value.name),
              ),
              ListItem(
                title: Text('哔咔账号', style: context.textTheme.titleMedium),
                trailing: Text(value.email),
              ),
              ListItem(
                title: Text('出生日期', style: context.textTheme.titleMedium),
                trailing: Text(getFormattedDate(value.birthday)),
              ),
              ListItem(
                title: Text('类别', style: context.textTheme.titleMedium),
                trailing: Text(
                  (value.characters.isNotEmpty)
                      ? value.characters.join(', ')
                      : '--',
                ),
              ),
              ListItem(
                title: Text('自我介绍', style: context.textTheme.titleMedium),
                subtitle: Text(
                  value.slogan,
                  style: context.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: showSloganEditor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.title,
    required this.trailing,
    this.onTap,
    this.subtitle,
  });

  final Widget title;

  final Widget trailing;

  final Widget? subtitle;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [title, ?subtitle],
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}
