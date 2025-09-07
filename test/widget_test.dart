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
  final local = Version.parse('1.0.0-beta.15');
  final remote = Version.parse('1.0.0');

  print(local.compareTo(remote) < 0);
}
