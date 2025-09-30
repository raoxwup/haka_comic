import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/database/word_block_helper.dart';

class BlockedStream {
  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() => _controller.add(null);
}

mixin BlockedWordsMixin<T extends StatefulWidget> on State<T> {
  final _tagBlockHelper = TagBlockHelper();
  List<String> blockedTags = [];

  Future<void> _getBlockedTags() async {
    final tags = await _tagBlockHelper.query();
    setState(() {
      blockedTags = tags;
    });
  }

  final _wordBlockHelper = WordBlockHelper();
  List<String> blockedWords = [];

  Future<void> _getBlockedWords() async {
    final words = await _wordBlockHelper.query();
    setState(() {
      blockedWords = words;
    });
  }

  @override
  void initState() {
    super.initState();
    _getBlockedTags();
    _tagBlockHelper.addListener(_getBlockedTags);
    _getBlockedWords();
    _wordBlockHelper.addListener(_getBlockedWords);
  }

  @override
  void dispose() {
    _tagBlockHelper.removeListener(_getBlockedTags);
    _wordBlockHelper.removeListener(_getBlockedWords);
    super.dispose();
  }
}
