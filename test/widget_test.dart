import 'package:haka_comic/utils/version.dart';

void main() {
  final local = Version.parse('1.0.0-beta1');
  final remote = Version.parse('1.0.0-beta2');

  print(local.compareTo(remote) < 0);
}
