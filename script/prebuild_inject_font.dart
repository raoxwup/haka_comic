import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  const harmonySansLink =
      "https://developer.huawei.com/images/download/general/HarmonyOS-Sans.zip";

  var dio = Dio();
  await dio.download(harmonySansLink, "HarmonyOS-Sans.zip");
  await extractFileToDisk("HarmonyOS-Sans.zip", "./assets/");
  File("HarmonyOS-Sans.zip").deleteSync();

  var pubspec = await File("pubspec.yaml").readAsString();
  pubspec = pubspec.replaceFirst("# fonts:", """  fonts:
  - family: HarmonyOS Sans
    fonts:
      - asset: assets/HarmonyOS Sans/HarmonyOS_Sans_SC/HarmonyOS_Sans_SC_Regular.ttf
""");
  await File("pubspec.yaml").writeAsString(pubspec);

  var mainDart = await File("lib/main.dart").readAsString();
  mainDart = mainDart.replaceFirst("霞鹜文楷", "HarmonyOS Sans");
  await File("lib/main.dart").writeAsString(mainDart);

  print("Successfully patched font.");
}

Future<void> extractFileToDisk(String zipPath, String targetDir) async {
  ProcessResult result;

  if (Platform.isWindows) {
    result = await Process.run('tar', [
      '-xf',
      zipPath,
      '-C',
      targetDir,
    ], runInShell: true);
  } else if (Platform.isMacOS || Platform.isLinux) {
    result = await Process.run('unzip', ['-o', zipPath, '-d', targetDir]);
  } else {
    throw UnsupportedError('Unsupported operating system');
  }

  if (result.exitCode != 0) {
    throw Exception(
      'Failed to extract zip file:\n'
      '${result.stderr}',
    );
  }
}
