import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool _needAuth = AppConf().needAuth;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('身份验证'),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: context.colorScheme.primary.withValues(alpha: .1),
        child: const Icon(Icons.security_outlined, size: 22),
      ),
      trailing: Switch(
        value: _needAuth,
        onChanged: (value) {
          setState(() {
            _needAuth = value;
            AppConf().needAuth = value;
          });
        },
      ),
    );
  }
}
