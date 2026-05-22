/// 纯 Dart 繁简中文转换器，基于 OpenCC 字典数据。
///
/// 零原生依赖，全平台通用。字典从 assets/dict/ 启动时加载。
/// 词组匹配使用 Trie 结构，O(n) 时间复杂度。
library;

import 'dart:convert';
import 'package:flutter/services.dart';

class ChineseConverter {
  ChineseConverter._();

  static final instance = ChineseConverter._();

  late final Map<String, String> _t2sChars;
  late final _TrieNode _t2sTrie;
  late final Map<String, String> _s2tChars;
  late final _TrieNode _s2tTrie;
  bool _initialized = false;

  // ── 初始化（在 StartupPrepare.prepare() 中调用） ────────────────────────

  /// 从 assets/dict/ 加载 OpenCC 字典。必须在使用转换方法前调用。
  Future<void> init() async {
    if (_initialized) return;
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/dict/t2s_chars.json'),
        rootBundle.loadString('assets/dict/t2s_phrases.json'),
        rootBundle.loadString('assets/dict/s2t_chars.json'),
        rootBundle.loadString('assets/dict/s2t_phrases.json'),
      ]);
      _t2sChars = Map<String, String>.from(jsonDecode(results[0]));
      _t2sTrie = _buildTrie(Map<String, String>.from(jsonDecode(results[1])));
      _s2tChars = Map<String, String>.from(jsonDecode(results[2]));
      _s2tTrie = _buildTrie(Map<String, String>.from(jsonDecode(results[3])));
      _initialized = true;
    } catch (e) {
      throw StateError(
        'Failed to load OpenCC dictionaries. '
        'Run "dart run script/download_opencc_dict.dart" first.\n'
        'Original error: $e',
      );
    }
  }

  // ── 公开 API（同步，init 后即可用） ─────────────────────────────────────

  /// 繁体中文 → 简体中文。
  String toSimplified(String input) {
    assert(_initialized, 'ChineseConverter.init() 尚未调用');
    if (input.isEmpty) return input;
    return _convert(input, _t2sChars, _t2sTrie);
  }

  /// 简体中文 → 繁体中文。
  String toTraditional(String input) {
    assert(_initialized, 'ChineseConverter.init() 尚未调用');
    if (input.isEmpty) return input;
    return _convert(input, _s2tChars, _s2tTrie);
  }

  /// 构建前缀树用于词组最长匹配。
  static _TrieNode _buildTrie(Map<String, String> phrases) {
    final root = _TrieNode();
    for (final entry in phrases.entries) {
      var node = root;
      for (var i = 0; i < entry.key.length; i++) {
        node = node.children.putIfAbsent(entry.key[i], _TrieNode.new);
      }
      node.value = entry.value;
    }
    return root;
  }

  /// 核心转换：逐字符扫描 + Trie 最长词组匹配。
  static String _convert(
    String input,
    Map<String, String> chars,
    _TrieNode trie,
  ) {
    final buf = StringBuffer();
    final len = input.length;
    var i = 0;
    while (i < len) {
      // 尝试词组最长匹配
      final phrase = trie.matchLongest(input, i);
      if (phrase != null) {
        buf.write(phrase.value);
        i += phrase.length;
        continue;
      }
      // 单字转换
      final char = input[i];
      buf.write(chars[char] ?? char);
      i++;
    }
    return buf.toString();
  }
}

// ── Trie 节点 ─────────────────────────────────────────────────────────────

class _TrieNode {
  final children = <String, _TrieNode>{};
  String? value; // 非 null 表示词组终点

  /// 从 input[start] 开始，返回最长匹配及其转换值。
  ({String value, int length})? matchLongest(String input, int start) {
    _TrieNode? node = this;
    String? bestValue;
    var bestLen = 0;
    var i = start;
    while (node != null && i < input.length) {
      node = node.children[input[i]];
      i++;
      if (node?.value != null) {
        bestValue = node!.value;
        bestLen = i - start;
      }
    }
    return bestValue != null ? (value: bestValue, length: bestLen) : null;
  }
}
