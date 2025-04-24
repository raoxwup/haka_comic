import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:image_picker/image_picker.dart';

class Editor extends StatefulWidget {
  const Editor({super.key, required this.user});

  final User? user;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      // 选择图片（相册）
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // 读取文件字节
        final bytes = await File(pickedFile.path).readAsBytes();
        // 转换为 Base64
        final base64 = base64Encode(bytes);
        print(base64);
        Toast.show(message: '已选择图片');
      }
    } catch (e) {
      Log.error("Error picking image", e);
      Toast.show(message: '选择图片失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('编辑')),
      body: ListView(
        children: [
          ListItem(
            onTap: _pickImage,
            title: Text('头像', style: context.textTheme.titleMedium),
            trailing: BaseImage(
              url: widget.user?.avatar?.url ?? '',
              width: 64,
              height: 64,
              shape: CircleBorder(),
            ),
          ),
          ListItem(
            title: Text('昵称', style: context.textTheme.titleMedium),
            trailing: Text(widget.user?.name ?? '--'),
          ),
          ListItem(
            title: Text('哔咔账号', style: context.textTheme.titleMedium),
            trailing: Text(widget.user?.email ?? '--'),
          ),
          ListItem(
            title: Text('出生日期', style: context.textTheme.titleMedium),
            trailing: Text(
              widget.user?.birthday != null
                  ? getFormattedDate(widget.user!.birthday)
                  : '--',
            ),
          ),
          ListItem(
            title: Text('类别', style: context.textTheme.titleMedium),
            trailing: Text(
              (widget.user?.characters != null &&
                      widget.user!.characters.isNotEmpty)
                  ? widget.user!.characters.join(', ')
                  : '--',
            ),
          ),
          ListItem(
            title: Text('自我介绍', style: context.textTheme.titleMedium),
            subtitle: Text(
              widget.user?.slogan ?? '',
              style: context.textTheme.bodySmall,
            ),
            trailing: Icon(Icons.edit_outlined),
            onTap: () {},
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
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
