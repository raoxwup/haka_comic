import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/images_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/read_record_helper.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/with_blur.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';

part 'vertical_list.dart';

const kBottomBarHeight = 105.0;

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

  /// 当前章节index
  late int _currentChapterIndex;

  /// 是否切换了章节
  bool _isChapterChanged = false;

  /// 是否显示顶部，底部工具栏
  final ValueNotifier<bool> _showToolbarNotifier = ValueNotifier(false);

  /// 当前可见的页码
  final ValueNotifier<int> _currentVisibleIndexNotifier = ValueNotifier(0);

  /// 滚动控制
  final ItemScrollController itemScrollController = ItemScrollController();

  /// 阅读记录
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

  // 初始页码
  int get initialIndex => _isChapterChanged ? 0 : widget.pageNo;

  int getCurrentChapterIndex() {
    return widget.chapters.indexWhere(
      (chapter) => chapter.id == widget.chapterId,
    );
  }

  void go(int index) {
    setState(() {
      _currentChapterIndex = index;
    });
    _currentVisibleIndexNotifier.value = 0;
    _isChapterChanged = true;
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
    _showToolbarNotifier.value = !_showToolbarNotifier.value;
    if (_showToolbarNotifier.value) {
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
              child: VerticalList(
                images: data,
                onItemVisibleChanged: onItemVisibleChanged,
                initialIndex: initialIndex,
                itemScrollController: itemScrollController,
              ),
            ),
          ),
          _buildChapterTag(data),
          if (!isLast) _buildNextActionButton(data),
          _buildAppBar(),
          _buildBottom(data),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final top = context.top;
    return ValueListenableBuilder(
      valueListenable: _showToolbarNotifier,
      builder: (context, value, child) {
        return AnimatedPositioned(
          duration: Duration(milliseconds: 250),
          top: value ? 0 : -(kToolbarHeight + top),
          left: 0,
          right: 0,
          height: kToolbarHeight + top,
          child: WithBlur(
            child: AppBar(
              title: Text(currentChapter.title),
              backgroundColor: context.colorScheme.surface.withValues(
                alpha: 0.92,
              ),
              actions: [
                IconButton(icon: Icon(Icons.settings), onPressed: () {}),
              ],
            ),
          ),
        );
      },
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
            style: const TextStyle(
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
    return ValueListenableBuilder<int>(
      valueListenable: _currentVisibleIndexNotifier,
      builder: (context, currentIndex, child) {
        final isShow =
            !_handler.isLoading &&
            data.isNotEmpty &&
            currentIndex >= data.length - 2;

        return Positioned(
          right: context.right + 16,
          bottom: context.bottom + 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isShow ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isShow ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isShow,
                child: FloatingActionButton(
                  onPressed: goNext,
                  child: Icon(Icons.skip_next),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottom(List<ChapterImage> data) {
    final bottom = context.bottom;
    return ValueListenableBuilder(
      valueListenable: _showToolbarNotifier,
      builder: (context, value, child) {
        return AnimatedPositioned(
          bottom: value ? 0 : -(bottom + kBottomBarHeight),
          left: 0,
          right: 0,
          height: bottom + kBottomBarHeight,
          duration: Duration(milliseconds: 250),
          child: WithBlur(
            child: Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
              decoration: BoxDecoration(
                color: context.colorScheme.surface.withValues(alpha: 0.92),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: Icon(Icons.skip_previous),
                        onPressed: goPrevious,
                      ),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _currentVisibleIndexNotifier,
                          builder: (context, value, child) {
                            return data.length > 1
                                ? Slider(
                                  year2023: true,
                                  value: value.toDouble(),
                                  min: 0,
                                  max: (data.length - 1).toDouble(),
                                  divisions: data.length - 1,
                                  label: (value + 1).toString(),
                                  onChanged: (double value) {
                                    _currentVisibleIndexNotifier.value =
                                        value.toInt();
                                    itemScrollController.jumpTo(
                                      index: value.toInt(),
                                    );
                                  },
                                )
                                : SizedBox.shrink();
                          },
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: Icon(Icons.skip_next),
                        onPressed: goNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
