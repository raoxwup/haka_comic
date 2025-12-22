import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';

class BlockedStream {
  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() => _controller.add(null);
}

mixin BlockedWordsMixin<T extends StatefulWidget> on State<T> {
  late final StreamSubscription _subscription;

  List<ComicBase> get comics;
  List<ComicBase> filteredComics = [];

  final _tagBlockHelper = TagBlockHelper();
  List<String> blockedTags = [];

  Future<void> _getBlockedTags() async {
    final tags = await _tagBlockHelper.query();
    blockedTags = tags;
  }

  final _wordBlockHelper = WordBlockHelper();
  List<String> blockedWords = [];

  Future<void> _getBlockedWords() async {
    final words = await _wordBlockHelper.query();
    blockedWords = words;
  }

  @override
  void initState() {
    super.initState();
    _getBlockedTags();
    _tagBlockHelper.addListener(_getBlockedTags);

    _getBlockedWords();
    _wordBlockHelper.addListener(_getBlockedWords);

    _subscription = BlockedStream.stream.listen((_) {
      _getBlockedTags().whenComplete(() {
        setState(filterComics);
      });
    });
  }

  @override
  void dispose() {
    _tagBlockHelper.removeListener(_getBlockedTags);
    _wordBlockHelper.removeListener(_getBlockedWords);
    _subscription.cancel();
    super.dispose();
  }

  /// 过滤屏蔽的tag、关键词、分类
  Iterable<K> filterBlockedWords<K extends ComicBase>(List<K> list) {
    return list.where((comic) {
      // 屏蔽的tag
      final tag = comic.tags.firstWhereOrNull(
        (item) => blockedTags.contains(item),
      );
      // 屏蔽的分类
      final category = comic.categories.firstWhereOrNull(
        (item) => AppConf().blacklist.contains(item),
      );
      // 屏蔽的标题关键词
      final word = blockedWords.firstWhereOrNull(
        (word) => comic.title.contains(word),
      );
      return (tag ?? category ?? word) == null;
    });
  }

  void filterComics() {
    filteredComics = comics.where((comic) {
      // 屏蔽的tag
      final tag = comic.tags.firstWhereOrNull(
        (item) => blockedTags.contains(item),
      );
      // 屏蔽的分类
      final category = comic.categories.firstWhereOrNull(
        (item) => AppConf().blacklist.contains(item),
      );
      // 屏蔽的标题关键词
      final word = blockedWords.firstWhereOrNull(
        (word) => comic.title.contains(word),
      );
      return (tag ?? category ?? word) == null;
    }).toList();
  }
}
