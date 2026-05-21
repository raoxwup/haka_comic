import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/boolean_parser.dart';
import 'package:haka_comic/utils/zh_hans.dart';

/// 构建单个漫画的匹配文本（简体 + 小写）
///
/// 拼接 title + author + description + tags + categories，繁体转简体后小写化。
/// 对齐 picacg-qt Search2 的搜索范围（title/author/description/tags/categories）。
/// 用于客户端布尔过滤，确保繁简/大小写都能匹配。
String buildMatchText(SearchComic comic) {
  final parts = <String>[
    comic.title,
    comic.author,
    if (comic.chineseTeam != null && comic.chineseTeam!.isNotEmpty)
      comic.chineseTeam!,
    if (comic.description != null && comic.description!.isNotEmpty)
      comic.description!,
    ...comic.tags,
    ...comic.categories,
  ];
  return toSimplified(parts.join(' ')).trim().toLowerCase();
}

/// 客户端布尔过滤：按 andWords / notWords 过滤 API 返回结果
///
/// 匹配时自动做繁简转换 + 大小写规范化，确保：
/// - "教師" 能匹配简体 "教师"
/// - "NTR" 能匹配 "ntr"
List<SearchComic> applyBooleanFilter(
  List<SearchComic> docs,
  SearchQuery query,
) {
  if (query.andWords.isEmpty && query.notWords.isEmpty && query.orWords.isEmpty) {
    return docs;
  }
  // 预处理搜索词：繁体→简体→小写
  final orNorm = query.orWords.map(_normalize).toList();
  final andNorm = query.andWords.map(_normalize).toList();
  final notNorm = query.notWords.map(_normalize).toList();
  return docs.where((comic) {
    final text = buildMatchText(comic);
    // OR 词：至少匹配一个
    if (orNorm.isNotEmpty && !orNorm.any((w) => text.contains(w))) {
      return false;
    }
    // AND 词：全部必须匹配
    for (final w in andNorm) {
      if (!text.contains(w)) return false;
    }
    // NOT 词：全部不能匹配
    for (final w in notNorm) {
      if (text.contains(w)) return false;
    }
    return true;
  }).toList();
}

/// 规范化搜索词：繁体→简体→小写
String _normalize(String s) => toSimplified(s).toLowerCase();


