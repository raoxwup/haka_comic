import 'package:flutter/material.dart';
import 'package:haka_comic/utils/shared_preferences_util.dart';

class SearchProvider with ChangeNotifier {
  static const historyLength = 20;
  final List<String> _history = [];

  List<String> get history => _history;

  SearchProvider() {
    final history = SharedPreferencesUtil.prefs.getStringList('search_history');
    if (history != null) {
      _history.addAll(history);
      notifyListeners();
    }
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
    useCache();
  }

  void useCache() {
    SharedPreferencesUtil.prefs.setStringList('search_history', _history);
  }
}
