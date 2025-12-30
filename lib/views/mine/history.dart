import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class ComicsWithTotal<T> {
  final List<T> comics;
  final int total;
  final int page;

  const ComicsWithTotal({
    required this.comics,
    required this.total,
    required this.page,
  });

  static ComicsWithTotal<HistoryDoc> empty = const ComicsWithTotal(
    comics: [],
    total: 0,
    page: 0,
  );
}

Future<ComicsWithTotal<HistoryDoc>> getComicsWithTotal(int page) async {
  final helper = HistoryHelper();
  final total = await helper.count();
  final comics = await helper.query(page);
  return ComicsWithTotal(comics: comics, total: total, page: page);
}

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> with RequestMixin, PaginationMixin {
  final _helper = HistoryHelper();

  @override
  bool get pagination => false;

  late final _handler = getComicsWithTotal.useRequest(
    defaultParams: 1,
    onSuccess: (data, _) {
      Log.info('Get history success', data.toString());
    },
    onError: (e, _) {
      Log.error('Get history error', e);
    },
    reducer: (prev, current) {
      if (prev == null) return current;
      return ComicsWithTotal(
        comics: [...prev.comics, ...current.comics],
        total: current.total,
        page: current.page,
      );
    },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  void _listener() {
    final event = _helper.lastEvent;
    if (event == null) return;
    switch (event) {
      case DeleteAllEvent():
        _update();
      case InsertEvent(comic: final _):
        _update();
      default:
        Log.info('Unknown event', event.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _helper.addListener(_listener);
  }

  @override
  void dispose() {
    _helper.removeListener(_listener);
    super.dispose();
  }

  void _update() {
    scrollController.jumpTo(0.0);
    _handler.mutate(ComicsWithTotal.empty);
    _handler.run(1);
  }

  @override
  Future<void> loadMore() async {
    final total = _handler.state.data?.total ?? 0;
    final length = _handler.state.data?.comics.length ?? 0;
    if (length >= total) return;
    final page = _handler.state.data?.page ?? 1;
    await _handler.run(page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近浏览'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('清除最近浏览'),
                    content: const Text('确定要清除最近浏览记录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          _helper.deleteAll();
                          context.pop();
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.clear_all),
            tooltip: '清除最近浏览',
          ),
        ],
      ),
      body: switch (_handler.state) {
        RequestState(:final data) when data != null => CommonTMIList(
          controller: scrollController,
          comics: data.comics,
          onTapDown: (details) => _details = details,
          onLongPress: (item) {
            _showContextMenu(context, _details.globalPosition, item);
          },
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _update,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  late TapDownDetails _details;

  void _showContextMenu(BuildContext context, Offset offset, Doc item) async {
    // 获取屏幕尺寸信息
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final screenSize = overlay.size;

    // 创建相对位置矩形
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy, 1, 1),
      Offset.zero & screenSize,
    );

    // 显示菜单
    final String? result = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: ListTile(leading: Icon(Icons.copy), title: Text('复制标题')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: context.colorScheme.error),
            title: Text(
              '删除记录',
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ),
      ],
      elevation: 4,
    );

    switch (result) {
      case 'copy':
        final title = item.title;
        await Clipboard.setData(ClipboardData(text: title));
        Toast.show(message: '已复制');
        break;
      case 'delete':
        _helper.delete(item.uid);
        final comics =
            _handler.state.data?.comics
                .where((c) => c.uid != item.uid)
                .toList() ??
            [];
        final total = _handler.state.data?.total ?? 0;
        final page = comics.isEmpty ? 1 : _handler.state.data?.page ?? 1;
        _handler.mutate(
          ComicsWithTotal(comics: comics, total: total - 1, page: page),
        );
        break;
    }
  }
}
