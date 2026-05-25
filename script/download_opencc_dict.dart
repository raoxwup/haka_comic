/// Build-time script: download OpenCC dictionaries from GitHub, generate JSON assets.
///
/// Usage: dart run script/download_opencc_dict.dart
///
/// Skips download if all JSON files already exist locally.
/// Exits with code 1 on failure (safe for CI).
///
/// Source: https://github.com/BYVoid/OpenCC/tree/master/data/dictionary
/// Output:
///   assets/dict/t2s_chars.json    Traditional -> Simplified (characters)
///   assets/dict/t2s_phrases.json  Traditional -> Simplified (phrases)
library;

import 'dart:convert';
import 'dart:io';

const _baseUrl =
    'https://raw.githubusercontent.com/BYVoid/OpenCC/master/data/dictionary';

const _sources = {
  't2s_chars': '$_baseUrl/TSCharacters.txt',
  't2s_phrases': '$_baseUrl/TSPhrases.txt',
};

Future<void> main() async {
  final outDir = Directory('assets/dict');

  // Clean up stale s2t files removed in the t2s-only migration.
  for (final stale in ['s2t_chars.json', 's2t_phrases.json']) {
    final f = File('${outDir.path}/$stale');
    if (f.existsSync()) {
      f.deleteSync();
      print('Removed stale dictionary: $stale');
    }
  }

  // Skip download if all output files already exist.
  if (_allExist(outDir)) {
    print('OpenCC dictionaries already exist, skipping download.');
    return;
  }

  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  for (final entry in _sources.entries) {
    final name = entry.key;
    final url = entry.value;
    final outFile = File('${outDir.path}/$name.json');

    print('Downloading $name ...');
    final text = await _fetch(url);
    if (text == null) {
      stderr.writeln('Failed to download $name from $url');
      exit(1);
    }

    final map = _parse(text);
    final jsonStr = jsonEncode(map);
    await outFile.writeAsString(jsonStr);
    print('Successfully generated $name.json (${map.length} entries, ${_fmtSize(jsonStr.length)}).');
  }

  print('All OpenCC dictionaries generated to assets/dict/.');
}

bool _allExist(Directory outDir) {
  for (final name in _sources.keys) {
    if (!File('${outDir.path}/$name.json').existsSync()) return false;
  }
  return true;
}

Future<String?> _fetch(String url) async {
  try {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    if (res.statusCode == 200) {
      final body = await res.transform(utf8.decoder).join();
      client.close();
      return body;
    }
    client.close();
  } catch (e) {
    stderr.writeln('Network error: $e');
  }
  return null;
}

/// Parse OpenCC text dictionary: each line is "key\tvalue" (multi-value: take first).
Map<String, String> _parse(String text) {
  final map = <String, String>{};
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final tab = trimmed.indexOf('\t');
    if (tab < 0) continue;
    final key = trimmed.substring(0, tab);
    final raw = trimmed.substring(tab + 1);
    final value = raw.contains(' ') ? raw.substring(0, raw.indexOf(' ')) : raw;
    if (key.isNotEmpty && value.isNotEmpty) map[key] = value;
  }
  return map;
}

String _fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  return '${(bytes / 1024).toStringAsFixed(1)} KB';
}
