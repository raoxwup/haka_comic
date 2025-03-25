import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/reader/vertical_list.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Reader extends StatefulWidget {
  const Reader({
    super.key,
    required this.id,
    required this.chapters,
    required this.chapterId,
  });

  /// 漫画id
  final String id;

  /// 漫画所有章节
  final List<Chapter> chapters;

  /// 开始章节id
  final String chapterId;

  /// 开始章节index
  int get startChapterIndex =>
      chapters.indexWhere((chapter) => chapter.id == chapterId);

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  final _handler = fetchChapterImages.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch chapter images success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch chapter images error', e);
    },
  );

  late int _currentChapterIndex;

  bool _showToolbar = false;

  final ValueNotifier<int> _currentVisibleIndexNotifier = ValueNotifier(0);

  void onItemVisibleChanged(int index) {
    _currentVisibleIndexNotifier.value = index;
  }

  void _update() => setState(() {});

  // 当前章节
  Chapter get currentChapter => widget.chapters[_currentChapterIndex];

  // 是否是最后一章
  bool get isLast => _currentChapterIndex == widget.chapters.length - 1;

  // 是否是第一章
  bool get isFirst => _currentChapterIndex == 0;

  void go(int index) {
    setState(() {
      _currentChapterIndex = index;
    });
    _handler.run(
      FetchChapterImagesPayload(
        id: widget.id,
        order: widget.chapters[index].order,
      ),
    );
  }

  /// 下一页
  void goNext() {
    if (isLast) return;
    go(_currentChapterIndex + 1);
  }

  /// 上一页
  void goPrevious() {
    if (isFirst) return;
    go(_currentChapterIndex - 1);
  }

  @override
  void initState() {
    _currentChapterIndex = widget.startChapterIndex;

    _handler
      ..addListener(_update)
      ..run(
        FetchChapterImagesPayload(id: widget.id, order: currentChapter.order),
      );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void openOrCloseToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
    });
    if (_showToolbar) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _handler.data ?? [];
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: BasePage(
              isLoading: _handler.isLoading,
              onRetry: _handler.refresh,
              error: _handler.error,
              child: GestureDetector(
                onTap: openOrCloseToolbar,
                child: VerticalList(
                  images: data,
                  onItemVisibleChanged: onItemVisibleChanged,
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 250),
            top: _showToolbar ? 0 : -(kToolbarHeight + top),
            left: 0,
            right: 0,
            height: kToolbarHeight + top,
            child: AppBar(title: Text(currentChapter.title)),
          ),
          _buildChapterTag(data),
        ],
      ),
    );
  }

  Widget _buildChapterTag(List<ChapterImage> data) {
    final padding = MediaQuery.paddingOf(context);
    return Positioned(
      left: padding.left,
      bottom: padding.bottom,
      child: ValueListenableBuilder(
        valueListenable: _currentVisibleIndexNotifier,
        builder: (context, value, child) {
          return Text(
            '第${_currentChapterIndex + 1}话 ${value + 1} / ${data.isEmpty ? 1 : data.length}',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              shadows: [
                // 添加8个方向的阴影（偏移1像素）
                Shadow(
                  offset: Offset(-1, -1),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(1, -1),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(-1, 1),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(1, 1),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(-1, 0),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(1, 0),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(0, -1),
                  color: Colors.white,
                  blurRadius: 0,
                ),
                Shadow(
                  offset: Offset(0, 1),
                  color: Colors.white,
                  blurRadius: 0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
