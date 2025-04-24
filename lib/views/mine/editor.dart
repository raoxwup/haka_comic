import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/base_image.dart';

class Editor extends StatefulWidget {
  const Editor({super.key, required this.user});

  final User? user;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('编辑')),
      body: ListView(
        children: [
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Text('头像', style: context.textTheme.bodyLarge),
                  const Spacer(),
                  BaseImage(
                    url: widget.user?.avatar?.url ?? '',
                    width: 64,
                    height: 64,
                    shape: CircleBorder(),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text('昵称'),
            trailing: Text(widget.user?.name ?? '--'),
          ),
          ListTile(
            title: Text('哔咔账号'),
            trailing: Text(widget.user?.email ?? '--'),
          ),
          ListTile(
            title: Text('出生日期'),
            trailing: Text(
              widget.user?.birthday != null
                  ? getFormattedDate(widget.user!.birthday)
                  : '--',
            ),
          ),
          ListTile(title: Text('类别'), trailing: Text('--')),
          ListTile(
            title: Text('自我介绍'),
            subtitle: Text(widget.user?.slogan ?? ''),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
