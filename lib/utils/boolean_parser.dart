/// 布尔查询解析器（对齐 picacg-qt Search2 的嵌套结构）
///
/// 语法：空格分隔，+ 前缀 AND，- 前缀 NOT
/// 示例："萝莉 +教师 -NTR" → OR:[萝莉], AND:[教师], NOT:[NTR]
/// 无运算符的纯文本（如"萝莉教师"）→ 整体作为 OR 关键词

/// 搜索布尔查询
/// 结构：(OR1 OR OR2 ...) AND (AND1 AND AND2 ...) AND (NOT1 AND NOT2 ...)
class SearchQuery {
  final List<String> orWords;
  final List<String> andWords;
  final List<String> notWords;

  const SearchQuery({
    this.orWords = const [],
    this.andWords = const [],
    this.notWords = const [],
  });

  bool get isEmpty => orWords.isEmpty && andWords.isEmpty && notWords.isEmpty;

  /// 提取第一个可用于服务器查询的关键词（优先 OR，再 AND）
  String? get firstServerKeyword {
    if (orWords.isNotEmpty) return orWords.first;
    if (andWords.isNotEmpty) return andWords.first;
    return null;
  }
}

/// 解析布尔搜索表达式
///
/// 语法：空格分隔，+ 前缀 AND，- 前缀 NOT
/// 示例："萝莉 +教师 -NTR" → OR:[萝莉], AND:[教师], NOT:[NTR]
/// 无运算符的纯文本（如"萝莉教师"）→ 整体作为 OR 关键词
SearchQuery parseSearchQuery(String input) {
  input = input.trim();
  if (input.isEmpty) return const SearchQuery();

  final parts = input.split(RegExp(r'\s+'));
  final andWords = <String>[];
  final notWords = <String>[];
  final orWords = <String>[];

  for (final part in parts) {
    if (part.startsWith('+') && part.length > 1) {
      andWords.add(part.substring(1));
    } else if (part.startsWith('-') && part.length > 1) {
      notWords.add(part.substring(1));
    } else {
      orWords.add(part);
    }
  }

  // 纯文本无运算符 → 整体作为单个 OR 关键词
  if (andWords.isEmpty && notWords.isEmpty) {
    return SearchQuery(orWords: [input]);
  }

  return SearchQuery(orWords: orWords, andWords: andWords, notWords: notWords);
}
