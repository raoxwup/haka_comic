import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/read_record_helper.dart';
import 'package:haka_comic/views/reader/vertical_list.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Reader extends StatefulWidget {
  const Reader({
    super.key,
    required this.id,
    required this.chapters,
    required this.chapterId,
    required this.pageNo,
  });

  /// 漫画id
  final String id;

  /// 漫画所有章节
  final List<Chapter> chapters;

  /// 开始章节id
  final String chapterId;

  /// 开始页码
  final int pageNo;

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
  final _helper = ReadRecordHelper();

  void onItemVisibleChanged(int index) {
    _currentVisibleIndexNotifier.value = index;
    _helper.insert(
      ComicReadRecord(
        cid: widget.id,
        chapterId: currentChapter.id,
        pageNo: index,
        chapterTitle: currentChapter.title,
      ),
    );
  }

  void _update() => setState(() {});

  // 当前章节
  Chapter get currentChapter => widget.chapters[_currentChapterIndex];

  // 是否是最后一章
  bool get isLast => _currentChapterIndex == widget.chapters.length - 1;

  // 是否是第一章
  bool get isFirst => _currentChapterIndex == 0;

  int getCurrentChapterIndex() {
    return widget.chapters.indexWhere(
      (chapter) => chapter.id == widget.chapterId,
    );
  }

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
    _currentChapterIndex = getCurrentChapterIndex();

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
                  cid: widget.id,
                  initialIndex: widget.pageNo,
                ),
              ),
            ),
          ),
          _buildAppBar(),
          _buildChapterTag(data),
          if (!isLast) _buildNextActionButton(data),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final top = context.top;
    return AnimatedPositioned(
      duration: Duration(milliseconds: 250),
      top: _showToolbar ? 0 : -(kToolbarHeight + top),
      left: 0,
      right: 0,
      height: kToolbarHeight + top,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // 模糊程度
          child: AppBar(
            title: Text(currentChapter.title),
            backgroundColor: context.colorScheme.inversePrimary.withAlpha(230),
            actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTag(List<ChapterImage> data) {
    return Positioned(
      left: context.left + 12,
      bottom: context.bottom + 12,
      width: context.width / 2,
      child: ValueListenableBuilder(
        valueListenable: _currentVisibleIndexNotifier,
        builder: (context, value, child) {
          return Text(
            '${currentChapter.title} ${value + 1} / ${data.isEmpty ? 1 : data.length}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildNextActionButton(List<ChapterImage> data) {
    // 获取浮动按钮的标准尺寸
    const fabHeight = kMinInteractiveDimension;

    return ValueListenableBuilder<int>(
      valueListenable: _currentVisibleIndexNotifier,
      builder: (context, currentIndex, child) {
        final isShow =
            !_handler.isLoading &&
            data.isNotEmpty &&
            currentIndex >= data.length - 2;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: 16,
          bottom: isShow ? 30 + context.bottom : -fabHeight * 1.5,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isShow ? 1.0 : 0.0,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: goNext,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
