import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;

  void _login() {
    context.replace('/');
  }

  void _update(_) => setState(() {});

  @override
  void initState() {
    final appConfig = AppConfig();
    _emailController.text = appConfig.email;
    _passwordController.text = appConfig.password;
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
      appBar: AppBar(),
      body: SingleChildScrollView(child: Center(child: _buildLoginForm())),
    );
  }

  Widget _buildLoginForm() {
    final enable =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
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
              obscureText: _showPassword,
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
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              onChanged: _update,
            ),
            FilledButton(
              onPressed: enable ? _login : null,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
