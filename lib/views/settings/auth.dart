import 'package:material_ui/material_ui.dart';
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
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.security_outlined, size: 22, weight: 700),
      ),
      subtitle: const Text('开启后需要验证才能访问应用'),
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
