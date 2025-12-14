import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';

class SearchProvider with ChangeNotifier {
  static const historyLength = 20;
  final List<String> _history = [];

  List<String> get history => _history;

  SearchProvider() {
    final history = AppConf().searchHistory;
    _history.addAll(history);
    notifyListeners();
  }

  void add(String keyword) {
    if (_history.contains(keyword)) {
      _history.remove(keyword);
    }
    if (_history.length >= historyLength) {
      _history.removeLast();
    }
    _history.insert(0, keyword);
    notifyListeners();
  }

  void remove(String keyword) {
    _history.remove(keyword);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    AppConf().searchHistory = _history;
  }
}
