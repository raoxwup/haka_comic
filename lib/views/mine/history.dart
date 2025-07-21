import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/widgets/toast.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final HistoryHelper _helper = HistoryHelper();
  final ScrollController _scrollController = ScrollController();

  List<HistoryDoc> _comics = [];
  int _comicsCount = 0;
  int _page = 1;

  bool _isLoading = false;

  bool get hasMore => _comics.length < _comicsCount;

  @override
  void initState() {
    _getComics(_page);
    _getComicsCount();
    _helper.addListener(_update);

    _scrollController.addListener(_onScroll);

    super.initState();
  }

  @override
  void dispose() {
    _helper.removeListener(_update);

    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  Future<void> _update() async {
    final comics = await _helper.query(1);
    setState(() {
      _comics = comics;
    });
  }

  Future<void> _getComics(int page) async {
    final comics = await _helper.query(page);
    setState(() {
      _comics.addAll(comics);
    });
  }

  Future<void> _getComicsCount() async {
    final count = await _helper.count();
    setState(() {
      _comicsCount = count;
    });
  }

  void _onScroll() {
    final position = _scrollController.position;
    // 添加保护条件，确保列表可滚动
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      if (hasMore && !_isLoading) {
        _isLoading = true;
        _page = _page + 1;
        _getComics(_page).whenComplete(() => _isLoading = false);
      }
    }
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
                          _page = 1;
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
      body: CommonTMIList(
        controller: _scrollController,
        comics: _comics,
        onTapDown: (details) => _details = details,
        onLongPress: (item) {
          _showContextMenu(context, _details.globalPosition, item);
        },
      ),
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
      Rect.fromLTWH(offset.dx, offset.dy, 1, 1), // 点击位置创建1x1矩形
      Offset.zero & screenSize, // 整个屏幕区域
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
        setState(() {
          _comics.removeWhere((comic) => comic.uid == item.uid);
          _comicsCount--;
          if (_comics.isEmpty) {
            _page = 1; // 重置页码
          }
        });
        break;
    }
  }
}
