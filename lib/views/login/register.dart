import 'package:flutter/material.dart';
import 'package:haka_comic/widgets/button.dart';

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
  final _genderController = TextEditingController();
  final _birthdateController = TextEditingController();
  final targetYear = DateTime.now().year - 18;
  // 'bot' -> 机器人 'm' -> 男 'f' -> 女
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: '昵称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: '确认密码',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          const DropdownMenu(
            label: Text('性别'),
            width: double.infinity,
            dropdownMenuEntries: [
              DropdownMenuEntry<String>(value: '男', label: '男'),
              DropdownMenuEntry<String>(value: '女', label: '女'),
              DropdownMenuEntry<String>(value: '机器人', label: '机器人'),
            ],
          ),
          // TextField(
          //   decoration: const InputDecoration(
          //     labelText: '出生日期',
          //     border: OutlineInputBorder(),
          //   ),
          //   controller: _birthdateController,
          //   onTap: () {
          //     showDatePicker(
          //       context: context,
          //       initialDate: DateTime(targetYear, 1, 1),
          //       firstDate: DateTime(1900),
          //       lastDate: DateTime(targetYear, 1, 1),
          //     ).then((value) {
          //       if (value != null) {
          //         // Handle selected date
          //         _birthdateController.text =
          //             '${value.year}-${value.month}-${value.day}';
          //       }
          //     });
          //   },
          // ),
          const SizedBox(height: 20),
          Button.filled(
            onPressed: () {
              // Handle registration
            },
            child: const Text('注册'),
          ),
        ],
      ),
    );
  }
}
