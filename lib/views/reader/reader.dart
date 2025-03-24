import 'package:flutter/material.dart';
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
    required this.startChapterIndex,
  });

  /// 漫画id
  final String id;

  /// 漫画所有章节
  final List<Chapter> chapters;

  /// 开始章节index
  final int startChapterIndex;

  Chapter get currentChapter => chapters[startChapterIndex];

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

  late int _currentIndex;

  void _update() => setState(() {});

  Chapter get currentChapter => widget.chapters[_currentIndex];

  bool get isLast => _currentIndex == widget.chapters.length - 1;

  bool get isFirst => _currentIndex == 0;

  void go(int index) {
    setState(() {
      _currentIndex = index;
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
    go(_currentIndex + 1);
  }

  /// 上一页
  void goPrevious() {
    if (isFirst) return;
    go(_currentIndex - 1);
  }

  @override
  void initState() {
    _currentIndex = widget.startChapterIndex;

    _handler
      ..addListener(_update)
      ..run(
        FetchChapterImagesPayload(id: widget.id, order: currentChapter.order),
      );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = _handler.data ?? [];
    return Scaffold(
      // appBar: AppBar(title: Text(widget.currentChapter.title)),
      body: Stack(
        children: [
          BasePage(
            isLoading: _handler.isLoading,
            onRetry: _handler.refresh,
            error: _handler.error,
            child: GestureDetector(
              onTap: () {
                print('tap');
              },
              child: VerticalList(images: data),
            ),
          ),
        ],
      ),
    );
  }
}
