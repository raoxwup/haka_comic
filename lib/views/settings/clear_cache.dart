import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path_provider/path_provider.dart';

class ClearCache extends StatefulWidget {
  const ClearCache({super.key});

  @override
  State<ClearCache> createState() => _ClearCacheState();
}

class _ClearCacheState extends State<ClearCache> {
  int _cacheSize = 0;
  bool _isClearing = false;
  bool _isCalculating = false;

  // 计算缓存大小
  static int _calculateCacheSizeIsolate(String dirPath) {
    final cacheDir = Directory(dirPath);
    int totalSize = 0;
    if (cacheDir.existsSync()) {
      final files = cacheDir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      }
    }
    return totalSize;
  }

  // 格式化文件大小
  String formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  // 清理缓存
  Future<void> clearCache() async {
    Directory cacheDir = await getTemporaryDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(); // 重新创建目录
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  void _loadCacheSize() async {
    setState(() => _isCalculating = true);
    final cacheDir = await getTemporaryDirectory();
    final size = await compute(_calculateCacheSizeIsolate, cacheDir.path);
    setState(() {
      _cacheSize = size;
      _isCalculating = false;
    });
  }

  // 清理缓存
  void _handleClearCache() async {
    setState(() => _isClearing = true);
    await clearCache();
    _loadCacheSize(); // 重新加载大小
    setState(() => _isClearing = false);
    Toast.show(message: '缓存已清除');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.cleaning_services),
      title: Text('清理缓存'),
      subtitle: Text(
        _isClearing
            ? "清理中..."
            : "缓存大小: ${_isCalculating ? '计算中...' : formatSize(_cacheSize)}",
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right),
      onTap: () => _handleClearCache(),
    );
  }
}
