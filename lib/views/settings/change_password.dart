import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';

class ChangePassword extends StatelessWidget {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withAction(
      icon: Icons.edit_outlined,
      title: '修改密码',
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

class _ChangePassWordDialogState extends State<ChangePassWordDialog>
    with RequestMixin {
  final controller = TextEditingController();

  late final _handler = updatePassword.useRequest(
    manual: true,
    onSuccess: (data, _) {
      Toast.show(message: '修改成功');
      context.pop();
    },
    onError: (e, _) {
      Toast.show(message: '修改失败');
    },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  void dispose() {
    controller.dispose();
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
          isLoading: _handler.state.loading,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
