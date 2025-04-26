import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/user_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final _avatarUpdateHandler = updateAvatar.useRequest(
    onSuccess: (data, _) {
      Toast.show(message: '头像更新成功');
      Log.info('Update avatar success', 'avatar');
      context.read<UserProvider>().userProfileHandler.run();
    },
    onError: (e, _) {
      Toast.show(message: '头像更新失败');
      Log.error('Update avatar error', e);
    },
  );

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      // 选择图片（相册）MacOS Windows Linux不支持maxWidth
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        // 读取文件字节
        final bytes = await File(pickedFile.path).readAsBytes();
        // 转换为 Base64
        final base64 = base64Encode(bytes);
        _avatarUpdateHandler.run(base64);
      }
    } catch (e) {
      Log.error("Error picking image", e);
      Toast.show(message: '选择图片失败');
    }
  }

  void showSloganEditor() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(20),
          title: const Text('编辑'),
          children: [
            TextField(
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (s) {
                context.pop();
              },
            ),
            Row(
              children: [
                Spacer(),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _avatarUpdateHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserProvider, User?>((value) => value.user);
    return Scaffold(
      appBar: AppBar(title: Text('编辑')),
      body: ListView(
        children: [
          ListItem(
            onTap: _pickImage,
            title: Text('头像', style: context.textTheme.titleMedium),
            trailing: BaseImage(
              url: user?.avatar?.url ?? '',
              width: 64,
              height: 64,
              shape: CircleBorder(),
            ),
          ),
          ListItem(
            title: Text('昵称', style: context.textTheme.titleMedium),
            trailing: Text(user?.name ?? '--'),
          ),
          ListItem(
            title: Text('哔咔账号', style: context.textTheme.titleMedium),
            trailing: Text(user?.email ?? '--'),
          ),
          ListItem(
            title: Text('出生日期', style: context.textTheme.titleMedium),
            trailing: Text(
              user?.birthday != null ? getFormattedDate(user!.birthday) : '--',
            ),
          ),
          ListItem(
            title: Text('类别', style: context.textTheme.titleMedium),
            trailing: Text(
              (user?.characters != null && user!.characters.isNotEmpty)
                  ? user.characters.join(', ')
                  : '--',
            ),
          ),
          ListItem(
            title: Text('自我介绍', style: context.textTheme.titleMedium),
            subtitle: Text(
              user?.slogan ?? '',
              style: context.textTheme.bodySmall,
            ),
            trailing: Icon(Icons.edit_outlined),
            onTap: showSloganEditor,
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
              children: [title, if (subtitle != null) subtitle!],
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}
