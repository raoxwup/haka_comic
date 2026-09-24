import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> with RequestMixin, PaginationMixin {
  final _helper = HistoryHelper();

  @override
  bool get pagination => false;

  late final _handler = _helper.queryPage.useRequest(
    defaultParams: 1,
    onSuccess: (data, _) {
      Log.i('Get history success', data.toString());
    },
    onError: (e, _) {
      Log.e('Get history error', error: e);
    },
    reducer: (prev, current) {
      if (prev == null) return current;
      return HistoryPageResult(
        comics: [...prev.comics, ...current.comics],
        hasMore: current.hasMore,
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
      case DeleteEvent():
      case InsertEvent(comic: final _):
        _update();
      case RestoreEvent():
        _update();
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
    _handler.mutate(HistoryPageResult.empty);
    _handler.run(1);
  }

  @override
  Future<void> loadMore() async {
    final hasMore = _handler.state.data?.hasMore ?? false;
    if (!hasMore) return;
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
          onItemSelected: _onItemSelected,
          contextMenu: menu,
          controller: scrollController,
          comics: data.comics,
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _update,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

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
        '删除记录',
        style: TextStyle(fontFamily: isLinux ? 'HarmonyOS Sans' : null),
      ),
      icon: const Icon(Icons.delete),
      value: 'delete',
    ),
  ];

  late final menu = ContextMenu(entries: entries, padding: const .all(8.0));

  void _onItemSelected(dynamic key, ComicBase item) async {
    switch (key) {
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
        final page = comics.isEmpty ? 1 : _handler.state.data?.page ?? 1;
        _handler.mutate(
          HistoryPageResult(
            comics: comics,
            hasMore: _handler.state.data?.hasMore ?? false,
            page: page,
          ),
        );
        break;
    }
  }
}
