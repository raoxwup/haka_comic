import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _nicknameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _genderValue = 'm';
  final targetYear = DateTime.now().year - 18;

  late final _handler = register.useRequest(
    onSuccess: (data, _) {
      Log.info('Register success', '');
      Toast.show(message: '注册成功');
      context.pop();
    },
    onError: (e, _) {
      Log.error('Register error', e);
      showSnackBar(e.toString());
    },
  );

  void submit() {
    final nickname = _nicknameController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final gender = _genderValue;
    final birthday = DateTime(targetYear, 1, 1);

    if (nickname.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        gender.isEmpty) {
      Toast.show(message: '请填写完整信息');
      return;
    }

    if (nickname.length < 2) {
      Toast.show(message: '昵称长度至少为2');
      return;
    }

    if (password != confirmPassword) {
      Toast.show(message: '两次密码不一致');
      return;
    }

    _handler.run(
      RegisterPayload(
        name: nickname,
        password: password,
        email: username,
        gender: gender,
        birthday: '${birthday.year}-${birthday.month}-${birthday.day}',
      ),
    );
  }

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
    _nicknameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void onGenderChange(String? value) {
    setState(() {
      _genderValue = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '昵称',
              border: OutlineInputBorder(),
            ),
            controller: _nicknameController,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
            controller: _usernameController,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            controller: _passwordController,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: '确认密码',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            controller: _confirmPasswordController,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('性别：', style: context.textTheme.titleMedium),
              const SizedBox(width: 8),
              Radio(
                value: 'm',
                groupValue: _genderValue,
                onChanged: onGenderChange,
              ),
              const Text('男'),
              const SizedBox(width: 8),
              Radio(
                value: 'f',
                groupValue: _genderValue,
                onChanged: onGenderChange,
              ),
              const Text('女'),
              const SizedBox(width: 8),
              Radio(
                value: 'bot',
                groupValue: _genderValue,
                onChanged: onGenderChange,
              ),
              const Text('机器人'),
            ],
          ),
          const SizedBox(height: 20),
          Button.filled(
            onPressed: submit,
            isLoading: _handler.isLoading,
            child: const Text('注册'),
          ),
        ],
      ),
    );
  }
}
