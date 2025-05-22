import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/app_router.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/button.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  final handler = login.useRequest(
    onSuccess: (data, params) {
      Log.info('Sign in success', data.toString());
      AppConf.instance.email = params.email;
      AppConf.instance.password = params.password;
      AppConf.instance.token = data.token;
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
  void _listener() => _update(null);

  @override
  void initState() {
    _emailController.text = AppConf.instance.email;
    _passwordController.text = AppConf.instance.password;

    handler.addListener(_listener);
    handler.isLoading = false;

    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();

    handler
      ..removeListener(_listener)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            spacing: 20,
            children: [
              const SizedBox(height: 70),
              Image.asset('assets/images/login.png', width: 160),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final password = _passwordController.text;
    final email = _emailController.text;
    final enable = password.isNotEmpty && email.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 375),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: _update,
              onFieldSubmitted: (value) {
                _passwordFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              focusNode: _passwordFocusNode,
              decoration: InputDecoration(
                labelText: '密码',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon:
                    password.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        )
                        : null,
              ),
              onChanged: _update,
              onFieldSubmitted: (value) => enable ? _login() : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Button.filled(
                    onPressed: enable ? _login : null,
                    isLoading: handler.isLoading,
                    child: const Text('登录'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('没有账号？'),
                TextButton(
                  onPressed: () {
                    context.push('/register');
                  },
                  child: const Text('注册'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
