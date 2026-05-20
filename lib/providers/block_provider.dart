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

  // O(1) 查找集合，与 List 同步维护
  Set<String> _blockedTagSet = {};
  Set<String> _blockedWordSet = {};

  BlockProvider() {
    _sync();
  }

  Future<void> _sync() async {
    blockedTags = await tagHelper.query();
    blockedWords = await wordHelper.query();
    _blockedTagSet = blockedTags.toSet();
    _blockedWordSet = blockedWords.toSet();
    notifyListeners();
  }

  bool containsTag(String tag) => _blockedTagSet.contains(tag);

  bool containsWord(String word) => _blockedWordSet.contains(word);

  Future<void> insertTag(String tag) async {
    await tagHelper.insert(tag);
    blockedTags = [...blockedTags, tag];
    _blockedTagSet = {..._blockedTagSet, tag};
    notifyListeners();
  }

  Future<void> deleteTag(String tag) async {
    await tagHelper.delete(tag);
    blockedTags = [...blockedTags]..remove(tag);
    _blockedTagSet = blockedTags.toSet();
    notifyListeners();
  }

  Future<void> insertWord(String word) async {
    await wordHelper.insert(word);
    blockedWords = [...blockedWords, word];
    _blockedWordSet = {..._blockedWordSet, word};
    notifyListeners();
  }

  Future<void> deleteWord(String word) async {
    await wordHelper.delete(word);
    blockedWords = [...blockedWords]..remove(word);
    _blockedWordSet = blockedWords.toSet();
    notifyListeners();
  }

  /// 过滤屏蔽的tag、关键词、分类（使用 Set 实现 O(1) 查找）
  List<K> filterBlockedWords<K extends ComicBase>(List<K> list) {
    final blacklist = AppConf().blacklist;
    return list.where((comic) {
      if (comic.tags.any(_blockedTagSet.contains)) return false;
      if (comic.categories.any(blacklist.contains)) return false;
      if (_blockedWordSet.any((word) => comic.title.contains(word))) return false;
      return true;
    }).toList();
  }
}

extension BuildContextExt on BuildContext {
  List<E> filtered<E extends ComicBase>(List<E> list) =>
      watch<BlockProvider>().filterBlockedWords<E>(list);
}
