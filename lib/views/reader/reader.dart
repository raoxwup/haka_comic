import 'dart:async';
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
    required this.title,
  });

  /// 漫画id
  final String id;

  /// 漫画所有章节
  final List<Chapter> chapters;

  /// 开始章节id
  final String chapterId;

  /// 开始页码
  final int pageNo;

  /// 漫画名称
  final String title;

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  /// 章节图片请求处理器
  final _handler = fetchChapterImages.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch chapter images success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch chapter images error', e);
    },
  );

  /// 当前章节索引
  late int _currentChapterIndex;

  /// 标记是否切换了章节（用于重置页码）
  bool _isChapterChanged = false;

  /// 控制工具栏显示状态
  final ValueNotifier<bool> _showToolbarNotifier = ValueNotifier(false);

  /// 当前可见页码通知器
  final ValueNotifier<int> _currentVisibleIndexNotifier = ValueNotifier(0);

  /// 滚动控制器 - 用于精确控制列表滚动位置
  final ItemScrollController itemScrollController = ItemScrollController();

  /// 阅读记录数据库助手
  final _helper = ReadRecordHelper();

  /// 页面可见性变化回调
  /// 更新当前页码并保存阅读记录
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

  /// 触发UI更新的简化方法
  void _update() => setState(() {});

  /// 获取当前章节
  Chapter get currentChapter => widget.chapters[_currentChapterIndex];

  /// 检查是否为最后一章
  bool get isLast => _currentChapterIndex == widget.chapters.length - 1;

  /// 检查是否为第一章
  bool get isFirst => _currentChapterIndex == 0;

  /// 获取初始页码 - 章节切换时重置为0，否则使用传入的页码
  int get initialIndex => _isChapterChanged ? 0 : widget.pageNo;

  /// 根据章节ID查找对应的索引
  int getCurrentChapterIndex() {
    return widget.chapters.indexWhere(
      (chapter) => chapter.id == widget.chapterId,
    );
  }

  /// 跳转到指定章节
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

  /// 跳转到下一章
  void goNext() {
    if (isLast) return;
    go(_currentChapterIndex + 1);
  }

  /// 跳转到上一章
  void goPrevious() {
    if (isFirst) return;
    go(_currentChapterIndex - 1);
  }

  @override
  void initState() {
    super.initState();

    // 初始化当前章节索引
    _currentChapterIndex = getCurrentChapterIndex();

    // 设置监听器并加载初始章节
    _handler
      ..addListener(_update)
      ..run(
        FetchChapterImagesPayload(id: widget.id, order: currentChapter.order),
      );

    // 设置沉浸式阅读模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // 恢复系统UI模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// 切换工具栏显示状态
  void openOrCloseToolbar() {
    _showToolbarNotifier.value = !_showToolbarNotifier.value;
    // 根据工具栏状态切换系统UI模式
    SystemChrome.setEnabledSystemUIMode(
      _showToolbarNotifier.value
          ? SystemUiMode.edgeToEdge
          : SystemUiMode.immersive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _handler.data ?? [];

    return Scaffold(
      body: Stack(
        children: [
          // 主阅读区域
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
          // 章节标签
          _buildChapterTag(data),
          // 下一章按钮 - 仅在非最后一章时显示
          if (!isLast) _buildNextActionButton(data),
          // 顶部工具栏
          _buildAppBar(),
          // 底部控制栏
          _buildBottom(data),
        ],
      ),
    );
  }

  /// 构建顶部应用栏
  Widget _buildAppBar() {
    final top = context.top;
    return ValueListenableBuilder(
      valueListenable: _showToolbarNotifier,
      builder: (context, value, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          top: value ? 0 : -(kToolbarHeight + top),
          left: 0,
          right: 0,
          height: kToolbarHeight + top,
          child: WithBlur(
            child: AppBar(
              title: Text(widget.title),
              backgroundColor: context.colorScheme.surface.withValues(
                alpha: 0.92,
              ),
              actions: [
                IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建章节标签指示器
  Widget _buildChapterTag(List<ChapterImage> data) {
    return Positioned(
      left: context.left + 12,
      bottom: context.bottom + 12,
      width: context.width / 2,
      child: ValueListenableBuilder(
        valueListenable: _currentVisibleIndexNotifier,
        builder: (context, value, child) {
          final total = data.isEmpty ? 1 : data.length;
          return Text(
            '${currentChapter.title} ${value + 1} / $total',
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

  /// 构建下一章浮动按钮
  /// 仅在接近章节末尾时显示
  Widget _buildNextActionButton(List<ChapterImage> data) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentVisibleIndexNotifier,
      builder: (context, currentIndex, child) {
        // 仅在章节末尾附近显示下一章按钮
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
                  child: const Icon(Icons.skip_next),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建底部控制栏
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
          duration: const Duration(milliseconds: 250),
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
                        icon: const Icon(Icons.skip_previous),
                        onPressed: isFirst ? null : goPrevious,
                      ),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _currentVisibleIndexNotifier,
                          builder: (context, value, child) {
                            // 只有当有多个图片时才显示滑块
                            return data.length > 1
                                ? Slider(
                                  year2023: true,
                                  value: value.toDouble(),
                                  min: 0,
                                  max: (data.length - 1).toDouble(),
                                  divisions: data.length - 1,
                                  label: (value + 1).toString(),
                                  onChanged: (double value) {
                                    final intValue = value.toInt();
                                    _currentVisibleIndexNotifier.value =
                                        intValue;
                                    itemScrollController.jumpTo(
                                      index: intValue,
                                    );
                                  },
                                )
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_next),
                        onPressed: isLast ? null : goNext,
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
