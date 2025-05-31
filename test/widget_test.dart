import 'package:haka_comic/utils/version.dart';

extension StringExt on String {
  String substringSafe(int start, [int? end]) {
    if (start < 0 || (end != null && end < start)) {
      return '';
    }
    if (end == null || end > length) {
      end = length;
    }
    return substring(start, end);
  }
}

void main() {
  final local = Version.parse('1.0.0-beta1');
  final remote = Version.parse('1.0.0-beta2');

  final name = 'xxxxx';
  final a = name.substringSafe(0, 18);

  print(a);

  print(local.compareTo(remote) < 0);
}
