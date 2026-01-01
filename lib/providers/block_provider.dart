import 'package:flutter/widgets.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:provider/provider.dart';

class BlockProvider extends ChangeNotifier {
  final tagHelper = TagBlockHelper();
  final wordHelper = WordBlockHelper();
  List<String> blockedTags = [];
  List<String> blockedWords = [];

  BlockProvider() {
    _sync();
  }

  Future<void> _sync() async {
    blockedTags = await tagHelper.query();
    blockedWords = await wordHelper.query();
    notifyListeners();
  }

  bool containsTag(String tag) => blockedTags.contains(tag);

  bool containsWord(String word) => blockedWords.contains(word);

  Future<void> insertTag(String tag) async {
    await tagHelper.insert(tag);
    blockedTags = [...blockedTags, tag];
    notifyListeners();
  }

  Future<void> deleteTag(String tag) async {
    await tagHelper.delete(tag);
    blockedTags = [...blockedTags]..remove(tag);
    notifyListeners();
  }

  Future<void> insertWord(String word) async {
    await wordHelper.insert(word);
    blockedWords = [...blockedWords, word];
    notifyListeners();
  }

  Future<void> deleteWord(String word) async {
    await wordHelper.delete(word);
    blockedWords = [...blockedWords]..remove(word);
    notifyListeners();
  }

  /// 过滤屏蔽的tag、关键词、分类
  List<K> filterBlockedWords<K extends ComicBase>(List<K> list) {
    return list.where((comic) {
      if (comic.tags.any(blockedTags.contains)) return false;
      if (comic.categories.any(AppConf().blacklist.contains)) return false;
      if (blockedWords.any((word) => comic.title.contains(word))) return false;
      return true;
    }).toList();
  }
}

extension BuildContextExt on BuildContext {
  List<E> filtered<E extends ComicBase>(List<E> list) =>
      watch<BlockProvider>().filterBlockedWords<E>(list);
}
