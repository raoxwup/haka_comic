import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';

class ChangePassword extends StatelessWidget {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.edit_outlined),
      title: const Text('修改密码'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ChangePassWordDialog(),
        );
      },
    );
  }
}

class ChangePassWordDialog extends StatefulWidget {
  const ChangePassWordDialog({super.key});

  @override
  State<ChangePassWordDialog> createState() => _ChangePassWordDialogState();
}

class _ChangePassWordDialogState extends State<ChangePassWordDialog> {
  final controller = TextEditingController();

  late final _handler = updatePassword.useRequest(
    onSuccess: (data, _) {
      Toast.show(message: '修改成功');
      context.pop();
    },
    onError: (e, _) {
      Toast.show(message: '修改失败');
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    super.initState();
    _handler
      ..addListener(_update)
      ..isLoading = false;
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      title: const Text('修改密码'),
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '新密码',
          ),
        ),
        const SizedBox(height: 10),
        Button.filled(
          onPressed: () {
            final password = controller.text;
            if (password.isEmpty) {
              Toast.show(message: '请输入新密码');
              return;
            }
            _handler.run(
              UpdatePasswordPayload(
                newPassword: password,
                oldPassword: AppConf.instance.password,
              ),
            );
          },
          isLoading: _handler.isLoading,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
