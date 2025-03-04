import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/loading_wrapper.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final handler = login.useRequest(
    onSuccess: (data, params) {
      Log.info('Sign in success', data.toString());
      final appConfig = AppConfig();
      appConfig.email = params.email;
      appConfig.password = params.password;
      appConfig.token = data.token;
      appRouter.go('/');
    },
    onError: (e, _) {
      Log.error('Sign in failed', e);
      showSnackBar(e.toString());
    },
  );

  bool _showPassword = false;

  void _login() {
    handler.run(
      LoginPayload(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  void _update(_) => setState(() {});

  @override
  void initState() {
    final appConfig = AppConfig();
    _emailController.text = appConfig.email;
    _passwordController.text = appConfig.password;

    handler.addListener(() {
      _update(null);
    });

    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(child: Center(child: _buildLoginForm())),
    );
  }

  Widget _buildLoginForm() {
    final enable =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 150, 20, 0),
        child: Column(
          spacing: 20,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: _update,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: '密码',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              onChanged: _update,
            ),
            FilledButton(
              onPressed: enable ? _login : null,
              child: Builder(
                builder: (context) {
                  final textColor = DefaultTextStyle.of(context).style.color;
                  return handler.isLoading
                      ? CircularProgressIndicator(
                        constraints: BoxConstraints.tight(const Size(24, 24)),
                        strokeWidth: 2,
                        color: textColor,
                      )
                      : const Text('登录');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
