import 'package:flutter/material.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class AppConfig {
  static late AppConfig _instance;
  static final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // 账号
  String _email;
  // 密码
  String _password;
  // token
  String _token;

  AppConfig._({
    required String email,
    required String password,
    required String token,
  }) : _email = email,
       _password = password,
       _token = token;

  factory AppConfig() => _instance;

  static void init({
    required String email,
    required String password,
    required String token,
  }) {
    _instance = AppConfig._(email: email, password: password, token: token);
  }

  static get isLogged => _instance.token != '';

  static get hasAccount => _instance.email != '' && _instance.password != '';

  set email(String email) {
    _instance._email = email;
    SharedPreferencesUtil.prefs.setString('email', email);
  }

  set password(String password) {
    _instance._password = password;
    SharedPreferencesUtil.prefs.setString('password', password);
  }

  set token(String token) {
    _instance._token = token;
    SharedPreferencesUtil.prefs.setString('token', token);
  }

  String get email => _instance._email;
  String get password => _instance._password;
  String get token => _instance._token;
}
