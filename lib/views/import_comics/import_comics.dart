import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/rust/api/compress.dart';
import 'package:haka_comic/rust/api/simple.dart';
import 'package:haka_comic/utils/android_download_saver.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/loader.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/save_to_folder_ios.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/slide_transition_x.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum _ExportFileType { pdf, zip }

const _imageExts = {'.jpg', '.jpeg', '.png', '.webp'};

class _ImportedComic {
  final String title;
  final String directoryPath;
  final String coverPath;
  final int imageCount;

  const _ImportedComic({
    required this.title,
    required this.directoryPath,
    required this.coverPath,
    required this.imageCount,
  });
}

class ImportComics extends StatefulWidget {
  const ImportComics({super.key});

  @override
  State<ImportComics> createState() => _ImportComicsState();
}

class _ImportComicsState extends State<ImportComics> {
  List<_ImportedComic> _comics = [];
  bool _isLoading = false;
  bool _isSelecting = false;
  Set<String> _selectedComicPaths = {};

  final entries = <ContextMenuEntry>[
    MenuItem(
      label: Text(
        '复制标题',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.copy),
      value: 'copy',
    ),
    MenuItem(
      label: Text(
        '选中该项',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.check),
      value: 'select',
    ),
  ];

  late final menu = ContextMenu(
    entries: entries,
    padding: const EdgeInsets.all(8.0),
  );

  @override
  void initState() {
    super.initState();
    _loadImportedComics().wait();
  }

  List<_ImportedComic> get _selectedComics {
    return _comics
        .where((comic) => _selectedComicPaths.contains(comic.directoryPath))
        .toList();
  }

  Future<Directory> _getImportRootDirectory({bool create = false}) async {
    final downloadPath = await getDownloadDirectory();
    final root = Directory(p.join(downloadPath, 'import_comics'));
    if (create && !await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<List<File>> _listImages(String directoryPath) async {
    final files = await Directory(directoryPath)
        .list()
        .where(
          (entity) =>
              entity is File &&
              _imageExts.contains(p.extension(entity.path).toLowerCase()),
        )
        .cast<File>()
        .toList();

    files.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );
    return files;
  }

  Future<void> _loadImportedComics() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final root = await _getImportRootDirectory();
      if (!await root.exists()) {
        if (!mounted) return;
        setState(() {
          _comics = [];
          _selectedComicPaths.clear();
          _isSelecting = false;
        });
        return;
      }

      final directories = await root
          .list()
          .where((entity) => entity is Directory)
          .cast<Directory>()
          .toList();

      directories.sort(
        (a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()),
      );

      final comics = <_ImportedComic>[];
      for (final directory in directories) {
        final title = p.basename(directory.path);
        if (title.startsWith('.')) {
          continue;
        }

        final images = await _listImages(directory.path);
        if (images.isEmpty) {
          continue;
        }

        comics.add(
          _ImportedComic(
            title: title,
            directoryPath: directory.path,
            coverPath: images.first.path,
            imageCount: images.length,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _comics = comics;
        _selectedComicPaths = _selectedComicPaths
            .where((path) => comics.any((comic) => comic.directoryPath == path))
            .toSet();
        if (_selectedComicPaths.isEmpty) {
          _isSelecting = false;
        }
      });
    } catch (e, st) {
      Log.e('Load imported comics error', error: e, stackTrace: st);
      Toast.show(message: "读取导入漫画失败");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _import() async {
    Directory? tempDir;

    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null) return;

      final images = await _listImages(path);
      if (images.isEmpty) {
        Toast.show(message: "没有找到漫画图片");
        return;
      }

      if (mounted) {
        Loader.show(context);
      }

      final importRoot = await _getImportRootDirectory(create: true);
      final folderName = p.basename(path);
      final targetDirPath = p.join(importRoot.path, folderName);
      final targetDir = Directory(targetDirPath);

      tempDir = Directory(
        p.join(
          importRoot.path,
          '.${folderName}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await tempDir.create(recursive: true);

      for (final image in images) {
        final newPath = p.join(tempDir.path, p.basename(image.path));
        await image.copy(newPath);
      }

      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      await tempDir.rename(targetDirPath);
      tempDir = null;

      await _loadImportedComics();
      Toast.show(message: "导入成功");
    } catch (e, st) {
      Log.e('Import comics error', error: e, stackTrace: st);
      Toast.show(message: "导入失败");
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
    }
  }

  void _openReader(_ImportedComic comic) {
    // context.push(
    //   '/reader',
    //   extra: ComicState(
    //     id: task.comic.id,
    //     title: task.comic.title,
    //     chapters: chapters,
    //     pageNo: pageNo,
    //     chapter: chapter ?? chapters.first,
    //     type: ReaderType.local,
    //   ),
    // );
  }

  void _closeSelection() {
    if (!mounted) return;
    setState(() {
      _isSelecting = false;
      _selectedComicPaths.clear();
    });
  }

  Future<void> _onContextMenuItemPress(
    String value,
    _ImportedComic comic,
  ) async {
    switch (value) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: comic.title));
        Toast.show(message: '已复制');
        break;
      case 'select':
        if (!mounted) return;
        setState(() {
          _isSelecting = true;
          _selectedComicPaths.add(comic.directoryPath);
        });
        break;
    }
  }

  Future<void> _deleteSelectedComics() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('是否删除选中的已导入漫画？'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final selectedComics = _selectedComics.toList();

    try {
      if (mounted) {
        Loader.show(context);
      }

      for (final comic in selectedComics) {
        final directory = Directory(comic.directoryPath);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }

      await _loadImportedComics();
      Toast.show(message: '删除成功');
    } catch (e, st) {
      Log.e('Delete imported comics failed', error: e, stackTrace: st);
      Toast.show(message: '删除失败');
      await _loadImportedComics();
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
    }
  }

  Future<Directory> _createCleanTempDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final tempDir = Directory(p.join(cacheDir.path, 'temp_import_comics'));

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);
    return tempDir;
  }

  Future<void> _exportForDesktop({required _ExportFileType type}) async {
    try {
      final selectedDirectoryPath = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectoryPath == null) {
        Toast.show(message: "未选择导出目录");
        return;
      }

      if (mounted) {
        Loader.show(context);
      }

      for (final comic in _selectedComics) {
        final destPath = p.join(
          selectedDirectoryPath,
          '${comic.title.legalized}.${type.name}',
        );

        switch (type) {
          case _ExportFileType.pdf:
            await exportPdf(
              sourceFolderPath: comic.directoryPath,
              outputPdfPath: destPath,
            );
          case _ExportFileType.zip:
            await compress(
              sourceFolderPath: comic.directoryPath,
              outputZipPath: destPath,
              compressionMethod: CompressionMethod.stored,
            );
        }
      }

      Toast.show(message: "导出成功");
    } catch (e, st) {
      Log.e('Export imported comics failed', error: e, stackTrace: st);
      Toast.show(message: "导出失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      _closeSelection();
    }
  }

  Future<void> _exportForIos({required _ExportFileType type}) async {
    Future<String> exportZipFile() async {
      final tempDir = await _createCleanTempDirectory();
      final zipPath = p.join(tempDir.path, 'comics.zip');

      final zipper = await createZipper(
        zipPath: zipPath,
        compressionMethod: CompressionMethod.stored,
      );

      for (final comic in _selectedComics) {
        await zipper.addDirectory(dirPath: comic.directoryPath);
      }

      await zipper.close();

      return zipPath;
    }

    Future<String> exportPdfFile() async {
      final tempDir = await _createCleanTempDirectory();

      if (_selectedComics.length == 1) {
        final comic = _selectedComics.first;
        final destPath = p.join(tempDir.path, '${comic.title.legalized}.pdf');
        await exportPdf(
          sourceFolderPath: comic.directoryPath,
          outputPdfPath: destPath,
        );
        return destPath;
      }

      final zipPath = p.join(tempDir.path, 'comics.zip');
      final zipper = await createZipper(
        zipPath: zipPath,
        compressionMethod: CompressionMethod.stored,
      );

      for (final comic in _selectedComics) {
        final destPath = p.join(tempDir.path, '${comic.title.legalized}.pdf');
        await exportPdf(
          sourceFolderPath: comic.directoryPath,
          outputPdfPath: destPath,
        );
        await zipper.addFile(filePath: destPath);
      }

      await zipper.close();

      return zipPath;
    }

    try {
      if (mounted) {
        Loader.show(context);
      }

      final path = switch (type) {
        _ExportFileType.pdf => await exportPdfFile(),
        _ExportFileType.zip => await exportZipFile(),
      };

      final success = await SaveToFolderIos.copy(path);
      Toast.show(message: success ? "导出成功" : "导出失败");
    } catch (e, st) {
      Log.e('Export imported comics failed', error: e, stackTrace: st);
      Toast.show(message: "导出失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      _closeSelection();
    }
  }

  Future<void> _exportForAndroid({required _ExportFileType type}) async {
    final cacheDir = await getApplicationCacheDirectory();

    try {
      final version = await AndroidDownloadSaver.getAndroidVersion();

      if (version <= 28) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            if (!mounted) return;
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('缺少权限'),
                  content: const Text('请在设置中开启存储权限后重试'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        openAppSettings();
                        context.pop();
                      },
                      child: const Text('打开设置'),
                    ),
                  ],
                );
              },
            );
            return;
          }

          Toast.show(message: "没有必要的存储权限");
          return;
        }
      }

      if (mounted) {
        Loader.show(context);
      }

      for (final comic in _selectedComics) {
        final fileName = '${comic.title.legalized}.${type.name}';
        final destPath = p.join(cacheDir.path, fileName);

        switch (type) {
          case _ExportFileType.pdf:
            await exportPdf(
              sourceFolderPath: comic.directoryPath,
              outputPdfPath: destPath,
            );
          case _ExportFileType.zip:
            await compress(
              sourceFolderPath: comic.directoryPath,
              outputZipPath: destPath,
              compressionMethod: CompressionMethod.stored,
            );
        }

        await AndroidDownloadSaver.saveToDownloads(
          filePath: destPath,
          fileName: fileName,
        );
      }

      Toast.show(message: "导出成功");
    } catch (e, st) {
      Log.e('Export imported comics failed', error: e, stackTrace: st);
      Toast.show(message: "导出失败");
    } finally {
      if (mounted) {
        Loader.hide(context);
      }
      _closeSelection();
    }
  }

  VoidCallback? _exportAction({required _ExportFileType type}) {
    if (_selectedComicPaths.isEmpty) {
      return null;
    }

    return isAndroid
        ? () => _exportForAndroid(type: type)
        : isDesktop
        ? () => _exportForDesktop(type: type)
        : () => _exportForIos(type: type);
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入说明'),
        content: const Text(
          '只会导入所选目录下的 jpg/jpeg/png/webp 图片，子目录下的图片会被忽略。另外，为确保阅读以及拼接 PDF 时图片顺序正确，图片最好以数字命名，比如 001.jpg、002.jpg、003.jpg。',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('关闭')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSelecting) {
          _closeSelection();
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: _isSelecting
            ? _SelectionAppBar(
                selectedCount: _selectedComicPaths.length,
                onClose: _closeSelection,
                onDeselectAll: () =>
                    setState(() => _selectedComicPaths.clear()),
                onSelectAll: () => setState(
                  () => _selectedComicPaths = _comics
                      .map((comic) => comic.directoryPath)
                      .toSet(),
                ),
                onInvertSelection: () {
                  final allPaths = _comics
                      .map((comic) => comic.directoryPath)
                      .toSet();
                  setState(() {
                    _selectedComicPaths = allPaths.difference(
                      _selectedComicPaths,
                    );
                  });
                },
              )
            : _NormalAppBar(
                hasItems: _comics.isNotEmpty,
                onEnterSelection: () => setState(() => _isSelecting = true),
                onShowInstructions: _showInstructions,
              ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              if (_isLoading && _comics.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_comics.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Empty(height: 260),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: UiMode.m1(context)
                          ? width
                          : UiMode.m2(context)
                          ? width / 2
                          : width / 3,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                      childAspectRatio: 2.45,
                    ),
                    itemCount: _comics.length,
                    itemBuilder: (context, index) {
                      final comic = _comics[index];
                      final isSelected = _selectedComicPaths.contains(
                        comic.directoryPath,
                      );

                      return _ImportedComicItem(
                        comic: comic,
                        isSelecting: _isSelecting,
                        isSelected: isSelected,
                        contextMenu: menu,
                        onTap: () {
                          if (_isSelecting) {
                            setState(() {
                              if (isSelected) {
                                _selectedComicPaths.remove(comic.directoryPath);
                              } else {
                                _selectedComicPaths.add(comic.directoryPath);
                              }
                            });
                          } else {
                            _openReader(comic);
                          }
                        },
                        onItemSelected: _onContextMenuItemPress,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: _isSelecting
            ? null
            : FloatingActionButton(
                onPressed: _import,
                tooltip: '导入漫画',
                child: const Icon(Icons.add),
              ),
        persistentFooterButtons: _isSelecting
            ? [
                FilledButton.tonalIcon(
                  onPressed: _exportAction(type: _ExportFileType.pdf),
                  label: const Text('PDF'),
                  icon: const Icon(Icons.picture_as_pdf),
                ),
                FilledButton.tonalIcon(
                  onPressed: _exportAction(type: _ExportFileType.zip),
                  label: const Text('ZIP'),
                  icon: const Icon(Icons.folder_zip),
                ),
                FilledButton.tonalIcon(
                  onPressed: _selectedComicPaths.isEmpty
                      ? null
                      : _deleteSelectedComics,
                  label: const Text('删除'),
                  icon: const Icon(Icons.delete_forever),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colorScheme.error,
                    foregroundColor: context.colorScheme.onError,
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}

class _NormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasItems;
  final VoidCallback onEnterSelection;
  final VoidCallback onShowInstructions;

  const _NormalAppBar({
    required this.hasItems,
    required this.onEnterSelection,
    required this.onShowInstructions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('本地导入'),
      actions: [
        if (hasItems)
          IconButton(
            onPressed: onEnterSelection,
            icon: const Icon(Icons.checklist_rtl),
          ),
        IconButton(
          tooltip: '说明',
          onPressed: onShowInstructions,
          icon: const Icon(Icons.help_outline),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onDeselectAll;
  final VoidCallback onSelectAll;
  final VoidCallback onInvertSelection;

  const _SelectionAppBar({
    required this.selectedCount,
    required this.onClose,
    required this.onDeselectAll,
    required this.onSelectAll,
    required this.onInvertSelection,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) {
          return SlideTransitionX(
            position: animation,
            direction: AxisDirection.down,
            child: child,
          );
        },
        child: Text('$selectedCount', key: ValueKey(selectedCount)),
      ),
      leading: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      actions: [
        IconButton(onPressed: onDeselectAll, icon: const Icon(Icons.deselect)),
        IconButton(onPressed: onSelectAll, icon: const Icon(Icons.select_all)),
        IconButton(
          onPressed: onInvertSelection,
          icon: const Icon(Icons.repeat),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ImportedComicItem extends StatelessWidget {
  final _ImportedComic comic;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function(String, _ImportedComic) onItemSelected;
  final ContextMenu contextMenu;

  const _ImportedComicItem({
    required this.comic,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onItemSelected,
    required this.contextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ContextMenuRegion(
      key: ValueKey(comic.directoryPath),
      contextMenu: contextMenu,
      enableDefaultGestures: !isSelecting,
      onItemSelected: (value) => onItemSelected(value!, comic),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: context.colorScheme.secondaryContainer.withValues(
                    alpha: 0.65,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 90 / 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(comic.coverPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return ColoredBox(
                        color: context.colorScheme.surfaceContainerHigh,
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comic.title,
                      style: context.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${comic.imageCount} 张图片',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(99),
                      value: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
