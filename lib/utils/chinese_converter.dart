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

  /// 单字映射：codeUnit → 转换后的 codeUnits。用 64K 平坦数组直索，零 HashMap 开销。
  late final List<List<int>?> _t2sChars;
  late final _TrieNode _t2sTrie;
  late final List<List<int>?> _s2tChars;
  late final _TrieNode _s2tTrie;
  bool _initialized = false;

  /// 整段结果缓存（LRU 意图）：相同输入字符串直接返回。
  final _resultCache = <String, String>{};
  static const _cacheMaxEntries = 2048;

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
      _t2sChars = _buildCharArray(
        Map<String, String>.from(jsonDecode(results[0])),
      );
      _t2sTrie = _buildTrie(
        Map<String, String>.from(jsonDecode(results[1])),
      );
      _s2tChars = _buildCharArray(
        Map<String, String>.from(jsonDecode(results[2])),
      );
      _s2tTrie = _buildTrie(
        Map<String, String>.from(jsonDecode(results[3])),
      );
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
    return _cachedConvert(input, _t2sChars, _t2sTrie);
  }

  /// 简体中文 → 繁体中文。
  String toTraditional(String input) {
    assert(_initialized, 'ChineseConverter.init() 尚未调用');
    if (input.isEmpty) return input;
    return _cachedConvert(input, _s2tChars, _s2tTrie);
  }

  // ── 构建辅助 ──────────────────────────────────────────────────────────

  /// 将 String→String 字典转为 64K 平坦数组（codeUnit 直索）。
  /// BMP 范围内 0x0000–0xFFFF 全覆盖，零哈希开销。
  static List<List<int>?> _buildCharArray(Map<String, String> src) {
    final arr = List<List<int>?>.filled(65536, null);
    for (final e in src.entries) {
      arr[e.key.codeUnitAt(0)] = e.value.codeUnits;
    }
    return arr;
  }

  /// 构建前缀树（int 键 = code unit，结果缓存在节点内）。
  static _TrieNode _buildTrie(Map<String, String> phrases) {
    final root = _TrieNode();
    for (final entry in phrases.entries) {
      var node = root;
      final units = entry.key.codeUnits;
      for (var i = 0; i < units.length; i++) {
        node = node.children.putIfAbsent(units[i], _TrieNode.new);
      }
      node.value = entry.value.codeUnits;
    }
    return root;
  }

  // ── 核心转换 ──────────────────────────────────────────────────────────

  /// 带整段缓存的转换入口。
  String _cachedConvert(
    String input,
    List<List<int>?> chars,
    _TrieNode trie,
  ) {
    // 整段缓存命中（自然语言中同一字符串常被多次转换）
    final cached = _resultCache[input];
    if (cached != null) return cached;

    final result = _convert(input, chars, trie);

    // 简单淘汰：缓存满时清空（高频场景下命中率远高于淘汰率）
    if (_resultCache.length >= _cacheMaxEntries) _resultCache.clear();
    _resultCache[input] = result;
    return result;
  }

  /// 逐字符扫描 + Trie 最长词组匹配（纯 int 操作，零 String 分配）。
  static String _convert(
    String input,
    List<List<int>?> chars,
    _TrieNode trie,
  ) {
    final buf = StringBuffer();
    final len = input.length;
    var i = 0;
    while (i < len) {
      // ── 词组匹配：完整 Trie 遍历找最长匹配，命中缓存时跳过转换 ──
      _TrieNode? node = trie;
      _TrieNode? bestNode; // 最长匹配的终止节点
      var bestLen = 0;
      var j = i;
      while (node != null && j < len) {
        node = node.children[input.codeUnitAt(j)];
        j++;
        if (node != null && node.value != null) {
          bestNode = node;
          bestLen = j - i;
        }
      }
      if (bestNode != null) {
        // 节点级缓存：同一词组首次转换后缓存，后续直接复用
        final cached = bestNode.cachedResult;
        if (cached != null) {
          buf.write(cached);
        } else {
          final converted = String.fromCharCodes(bestNode.value!);
          bestNode.cachedResult = converted;
          buf.write(converted);
        }
        i += bestLen;
        continue;
      }
      // ── 单字转换：平坦数组直索，零 HashMap 查找 ──
      final codeUnit = input.codeUnitAt(i);
      final mapped = chars[codeUnit];
      buf.write(mapped != null ? String.fromCharCodes(mapped) : input[i]);
      i++;
    }
    return buf.toString();
  }
}

// ── Trie 节点（int 键 = code unit） ──────────────────────────────────────

class _TrieNode {
  /// children 的键是 code unit (int)，避免每步创建 String 对象。
  final children = <int, _TrieNode>{};

  /// 非 null 表示词组终点，值为转换后的 code units。
  List<int>? value;

  /// 节点级缓存：同一子串首次转换后缓存 String 结果。
  /// 重复出现时直接写入 StringBuffer，跳过 String.fromCharCodes。
  String? cachedResult;
}
