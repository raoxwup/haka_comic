import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }

  late VoidCallback refresh;
}
