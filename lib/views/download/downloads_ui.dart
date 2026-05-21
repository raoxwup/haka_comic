import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/comic_exporter.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/download/background_downloader.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/slide_transition_x.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:haka_comic/widgets/ui_image.dart';
import 'package:path/path.dart' as p;

typedef _DownloadTaskAction = ({
  IconData icon,
  void Function(String taskId) action,
});

enum DownloadTaskSortOrder {
  oldestFirst('旧到新'),
  newestFirst('新到旧');

  const DownloadTaskSortOrder(this.label);

  final String label;

  static DownloadTaskSortOrder fromName(String? name) {
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => oldestFirst,
    );
  }
}

_DownloadTaskAction _resolveDownloadTaskAction(DownloadTaskStatus status) {
  return switch (status) {
    DownloadTaskStatus.paused => (
      icon: Icons.play_arrow,
      action: BackgroundDownloader.resumeTask,
    ),
    DownloadTaskStatus.downloading => (
      icon: Icons.pause,
      action: BackgroundDownloader.pauseTask,
    ),
    DownloadTaskStatus.error => (
      icon: Icons.refresh,
      action: BackgroundDownloader.resumeTask,
    ),
    _ => (icon: Icons.error, action: (_) {}),
  };
}

class Downloads extends StatefulWidget {
  const Downloads({
    super.key,
    this.taskStream,
    this.speedStream,
    this.onRequestTasks,
  });

  final Stream<List<ComicDownloadTask>>? taskStream;
  final Stream<int>? speedStream;
  final VoidCallback? onRequestTasks;

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  List<ComicDownloadTask> tasks = [];
  late final StreamSubscription _subscription;
  late final StreamSubscription<int> _speedSubscription;
  bool _isSelecting = false;
  Set<String> _selectedTaskIds = {};
  int _downloadSpeed = 0;
  late DownloadTaskSortOrder _sortOrder = AppConf().downloadTaskSortOrder;

  @override
  void initState() {
    super.initState();
    _subscription =
        (widget.taskStream ?? BackgroundDownloader.streamController.stream)
            .listen(
              (event) => setState(() {
                tasks = event;
              }),
            );
    _speedSubscription =
        (widget.speedStream ??
                BackgroundDownloader.speedStreamController.stream)
            .listen((speed) => setState(() => _downloadSpeed = speed));
    (widget.onRequestTasks ?? BackgroundDownloader.getTasks).call();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _speedSubscription.cancel();
    super.dispose();
  }

  List<ComicDownloadTask> get _selectedTasks {
    return tasks
        .where((task) => _selectedTaskIds.contains(task.comic.id))
        .toList();
  }

  List<ComicDownloadTask> get _displayTasks {
    return switch (_sortOrder) {
      DownloadTaskSortOrder.oldestFirst => tasks,
      DownloadTaskSortOrder.newestFirst => tasks.reversed.toList(),
    };
  }

  void _setSortOrder(DownloadTaskSortOrder sortOrder) {
    if (_sortOrder == sortOrder) {
      return;
    }

    setState(() => _sortOrder = sortOrder);
    AppConf().downloadTaskSortOrder = sortOrder;
  }

  void clearTasks() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('是否删除选中的下载任务？'),
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

    if (result == true) {
      BackgroundDownloader.deleteTasks(_selectedTaskIds.toList());
      close();
    }
  }

  bool get _canExportSelectedTasks {
    return _selectedTaskIds.isNotEmpty && isAllCompleted;
  }

  Future<List<ComicExportItem>> _getSelectedExportItems() async {
    final downloadPath = await getDownloadDirectory();
    return [
      for (final task in _selectedTasks)
        (
          fileStem: task.comic.title.legalized,
          sourceFolderPath: p.join(downloadPath, task.comic.title.legalized),
        ),
    ];
  }

  Future<void> _exportSelectedTasks({required ExportFileType type}) async {
    final items = await _getSelectedExportItems();
    if (!mounted) return;
    await ComicExporter.export(
      context: context,
      items: items,
      type: type,
      onComplete: close,
    );
  }

  VoidCallback? exportFile({required ExportFileType type}) {
    if (!_canExportSelectedTasks) {
      return null;
    }

    return () => _exportSelectedTasks(type: type);
  }

  void close() {
    setState(() {
      _isSelecting = false;
      _selectedTaskIds.clear();
    });
  }

  bool get isAllCompleted => _selectedTasks.every(
    (task) => task.status == DownloadTaskStatus.completed,
  );

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
    MenuItem(
      label: Text(
        '查看详情',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.details),
      value: 'details',
    ),
  ];

  late final menu = ContextMenu(
    entries: entries,
    padding: const EdgeInsets.all(8.0),
  );

  Future<void> _onContextMenuItemPress(
    String value,
    ComicDownloadTask task,
  ) async {
    switch (value) {
      case 'copy':
        final title = task.comic.title;
        await Clipboard.setData(ClipboardData(text: title));
        Toast.show(message: '已复制');
        break;
      case 'select':
        setState(() {
          _isSelecting = true;
          _selectedTaskIds.add(task.comic.id);
        });
        break;
      case 'details':
        context.push('/details/${task.comic.id}');
    }
  }

  void _startReader(ComicDownloadTask task) async {
    if (task.status != DownloadTaskStatus.completed) {
      Toast.show(message: '任务未完成');
      return;
    }
    final chapters = task.chapters.map((e) => e.toChapter()).toList();

    chapters.sort((a, b) => a.order.compareTo(b.order));

    final helper = ReadRecordHelper();

    final record = await helper.query(task.comic.id);

    var pageNo = 0;
    var chapter = chapters.firstWhereOrNull((e) => e.id == record?.chapterId);

    if (chapter != null) {
      pageNo = record!.pageNo;
    }

    if (!mounted) return;
    context.push(
      '/reader',
      extra: ComicState(
        id: task.comic.id,
        title: task.comic.title,
        chapters: chapters,
        pageNo: pageNo,
        chapter: chapter ?? chapters.first,
        type: ReaderType.local,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    final displayTasks = _displayTasks;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSelecting) {
          close();
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: _isSelecting
            ? _SelectionAppBar(
                selectedCount: _selectedTaskIds.length,
                onClose: close,
                onDeselectAll: () => setState(() => _selectedTaskIds.clear()),
                onSelectAll: () => setState(
                  () => _selectedTaskIds = tasks.map((e) => e.comic.id).toSet(),
                ),
                onInvertSelection: () {
                  final allIds = tasks.map((e) => e.comic.id).toSet();
                  setState(() {
                    _selectedTaskIds = allIds.difference(_selectedTaskIds);
                  });
                },
              )
            : _NormalAppBar(
                onEnterSelection: () => setState(() => _isSelecting = true),
                downloadSpeed: _downloadSpeed,
                sortOrder: _sortOrder,
                onSortOrderChanged: _setSortOrder,
              ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              if (tasks.isEmpty) const SliverToBoxAdapter(child: Empty()),
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: UiMode.m1(context)
                      ? width
                      : UiMode.m2(context)
                      ? width / 2
                      : width / 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  final task = displayTasks[index];
                  final isSelected = _selectedTaskIds.contains(task.comic.id);
                  return _DownloadTaskItem(
                    task: task,
                    isSelecting: _isSelecting,
                    isSelected: isSelected,
                    contextMenu: menu,
                    onTap: () {
                      if (_isSelecting) {
                        setState(() {
                          if (isSelected) {
                            _selectedTaskIds.remove(task.comic.id);
                          } else {
                            _selectedTaskIds.add(task.comic.id);
                          }
                        });
                      } else {
                        _startReader(task);
                      }
                    },
                    onItemSelected: _onContextMenuItemPress,
                    downloadSpeed: _downloadSpeed,
                  );
                },
                itemCount: displayTasks.length,
              ),
            ],
          ),
        ),
        persistentFooterButtons: _isSelecting
            ? [
                FilledButton.tonalIcon(
                  onPressed: exportFile(type: ExportFileType.pdf),
                  label: const Text('PDF'),
                  icon: const Icon(Icons.picture_as_pdf),
                ),
                FilledButton.tonalIcon(
                  onPressed: exportFile(type: ExportFileType.zip),
                  label: const Text('ZIP'),
                  icon: const Icon(Icons.folder_zip),
                ),
                FilledButton.tonalIcon(
                  onPressed: _selectedTaskIds.isEmpty ? null : clearTasks,
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

class _NormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onEnterSelection;
  final int downloadSpeed;
  final DownloadTaskSortOrder sortOrder;
  final ValueChanged<DownloadTaskSortOrder> onSortOrderChanged;

  const _NormalAppBar({
    required this.onEnterSelection,
    required this.downloadSpeed,
    required this.sortOrder,
    required this.onSortOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('我的下载'),
      actions: [
        PopupMenuButton<DownloadTaskSortOrder>(
          tooltip: '排序',
          icon: const Icon(Icons.sort),
          initialValue: sortOrder,
          onSelected: onSortOrderChanged,
          itemBuilder: (context) {
            return [
              for (final order in DownloadTaskSortOrder.values)
                CheckedPopupMenuItem<DownloadTaskSortOrder>(
                  value: order,
                  checked: order == sortOrder,
                  child: Text(order.label),
                ),
            ];
          },
        ),
        IconButton(
          onPressed: onEnterSelection,
          icon: const Icon(Icons.checklist_rtl),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

String _formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond >= 1024 * 1024) {
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)}MB/s';
  } else if (bytesPerSecond >= 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(0)}KB/s';
  }
  return '${bytesPerSecond}B/s';
}

class _DownloadTaskItem extends StatelessWidget {
  final ComicDownloadTask task;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function(String, ComicDownloadTask) onItemSelected;
  final ContextMenu contextMenu;
  final int downloadSpeed;

  const _DownloadTaskItem({
    required this.task,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onItemSelected,
    required this.contextMenu,
    required this.downloadSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return ContextMenuRegion(
      key: ValueKey(task.comic.id),
      contextMenu: contextMenu,
      enableDefaultGestures: !isSelecting,
      onItemSelected: (value) => onItemSelected(value!, task),
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
                child: UiImage(
                  url: task.comic.cover,
                  cacheWidth: 180,
                  shape: .rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.comic.title,
                      style: context.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (task.status.isOperable)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Builder(
                            builder: (_) {
                              final action = _resolveDownloadTaskAction(
                                task.status,
                              );
                              return IconButton(
                                onPressed: () {
                                  action.action(task.comic.id);
                                },
                                icon: Icon(action.icon),
                              );
                            },
                          ),
                        ],
                      ),
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          task.status.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${task.completed} / ${task.total}',
                          style: context.textTheme.bodySmall,
                        ),
                        if (downloadSpeed > 0 &&
                            task.status == DownloadTaskStatus.downloading)
                          Text(
                            _formatSpeed(downloadSpeed),
                            style: context.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(99),
                      value: task.total == 0
                          ? null
                          : task.completed / task.total,
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
