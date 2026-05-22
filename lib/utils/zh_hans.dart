import 'package:pinyin/pinyin.dart';

// ---------------------------------------------------------------------------
// 补充映射：pinyin 包基于 Unihan 数据库，对部分生僻/多义字可能不转换。
// 如遇新缺失在此添加即可。
// ---------------------------------------------------------------------------
const Map<String, String> _overrideMap = {
  '籤': '签',
  '韆': '千',
  '剋': '克',
  '纔': '才',
  '佈': '布',
  '佔': '占',
  '裏': '里',
  '濛': '蒙',
  '瀰': '弥',
  '檯': '台',
  '鹼': '碱',
};

/// 繁体中文→简体中文 转换。
/// 基于 Unicode Unihan 数据库（pinyin 包），覆盖数千字 + 词组级转换。
/// 对 pinyin 包未覆盖的边缘字（如 籤→签）做补充映射。
String toSimplified(String input) {
  if (input.isEmpty) return input;
  var result = ChineseHelper.convertToSimplifiedChinese(input);
  final buf = StringBuffer();
  for (var i = 0; i < result.length; i++) {
    buf.write(_overrideMap[result[i]] ?? result[i]);
  }
  return buf.toString();
}

