import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comic_details/chapters_list.dart';
import 'package:haka_comic/views/comic_details/comic_actions.dart';
import 'package:haka_comic/views/comic_details/creator.dart';
import 'package:haka_comic/views/comic_details/description_box.dart';
import 'package:haka_comic/views/comic_details/header_info.dart';
import 'package:haka_comic/views/comic_details/read_buttons.dart';
import 'package:haka_comic/views/comic_details/read_status_bar.dart';
import 'package:haka_comic/views/comic_details/recommendation.dart';
import 'package:haka_comic/views/comic_details/tag_group.dart';
import 'package:haka_comic/views/comic_details/title_box.dart';
import 'package:haka_comic/views/reader/state/comic_state.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class ComicDetails extends StatefulWidget {
  const ComicDetails({super.key, required this.id});

  final String id;

  @override
  State<ComicDetails> createState() => _ComicDetailsState();
}

class _ComicDetailsState extends State<ComicDetails> with RequestMixin {
  /// 漫画详情
  late final handler = fetchComicDetails.useRequest(
    defaultParams: widget.id,
    onSuccess: (data, _) {
      Log.info('Fetch comic details', data.toString());
      HistoryHelper().insert(data.comic);
    },
    onError: (e, _) {
      Log.error('Fetch comic details error', e);
    },
  );

  /// 漫画章节
  late final chaptersHandler = fetchChapters.useRequest(
    defaultParams: widget.id,
    onSuccess: (data, _) {
      Log.info('Fetch chapters success', data.toString());
      // 哔咔最新的排在最前面
      _chapters = data.reversed.toList();
    },
    onError: (e, _) {
      Log.error('Fetch chapters error', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [handler, chaptersHandler];

  final _showTitleNotifier = ValueNotifier(false);
  final _scrollController = ScrollController();
  final _scrollThreshold = 80.0;
  final _helper = ReadRecordHelper();

  // 阅读记录
  final ValueNotifier<ComicReadRecord?> _readRecordNotifier = ValueNotifier(
    null,
  );

  List<Chapter> _chapters = [];

  void _handleScroll() {
    final currentScroll = _scrollController.offset;
    final shouldShow = currentScroll > _scrollThreshold;

    if (shouldShow != _showTitleNotifier.value) {
      _showTitleNotifier.value = shouldShow;
    }
  }

  Future<void> _updateReadRecord() async {
    _readRecordNotifier.value = await _helper.query(widget.id);
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    _updateReadRecord();

    _helper.addListener(_updateReadRecord);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    _helper.removeListener(_updateReadRecord);
    _showTitleNotifier.dispose();
    _readRecordNotifier.dispose();

    super.dispose();
  }

  /// 进入阅读
  void _startRead({String? chapterId, int? pageNo}) {
    final data = handler.state.data!.comic;
    // 如果没有章节，直接返回
    if (_chapters.isEmpty) return;
    
    final chapter = _chapters.firstWhere(
      (element) => element.id == chapterId,
      orElse: () => _chapters.first,
    );
    context.push(
      '/reader',
      extra: ComicState(
        id: widget.id,
        title: data.title,
        chapters: _chapters,
        chapter: chapter,
        pageNo: pageNo ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = handler.state.data?.comic;

    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(
            title: ValueListenableBuilder<bool>(
              valueListenable: _showTitleNotifier,
              builder: (context, value, child) {
                return AnimatedOpacity(
                  opacity: value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(data?.title ?? ''),
                );
              },
            ),
            actions: [
              MenuAnchor(
                builder: (context, controller, widget) => IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                ),
                menuChildren: [
                  MenuItemButton(
                    style: MenuItemButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    leadingIcon: const Icon(Icons.copy, size: 17.0),
                    child: const Text('复制标题'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: data?.title ?? ''),
                      );
                      Toast.show(message: '已复制');
                    },
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (!completed) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (handler.state case Error(:final error)) {
                  return ErrorPage(
                    errorMessage: error.toString(),
                    onRetry: () {
                      handler.refresh();
                      chaptersHandler.refresh();
                    },
                  );
                }

                if (chaptersHandler.state case Error(:final error)) {
                  return ErrorPage(
                    errorMessage: error.toString(),
                    onRetry: () {
                      handler.refresh();
                      chaptersHandler.refresh();
                    },
                  );
                }

                return switch ((handler.state, chaptersHandler.state)) {
                  (Success(:final data), Success(data: final chapters)) =>
                    SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                      child: Column(
                        spacing: 15,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ComicHeaderInfo(data: data.comic),
                          if (data.comic.categories.isNotEmpty)
                            ComicTagGroup(data: data.comic, type: '分类'),
                          if (data.comic.tags.isNotEmpty)
                            ComicTagGroup(data: data.comic, type: '标签'),
                          
                          ValueListenableBuilder(
                            valueListenable: _readRecordNotifier,
                            builder: (context, value, child) {
                              return ComicActionBar(
                                comicId: widget.id,
                                data: data.comic,
                                readRecord: value,
                                onStartRead: _startRead,
                                chapters: chapters,
                              );
                            },
                          ),
                          
                          if (UiMode.m1(context))
                            ValueListenableBuilder(
                              valueListenable: _readRecordNotifier,
                              builder: (context, value, child) {
                                return ComicReadButtons(
                                  readRecord: value,
                                  onStartRead: _startRead,
                                );
                              },
                            ),
                            
                          ValueListenableBuilder(
                            valueListenable: _readRecordNotifier,
                            builder: (context, value, child) {
                              return ReadStatusBar(readRecord: value);
                            },
                          ),
                          
                          const Divider(),
                          ComicCreator(
                            creator: data.comic.creator,
                            updatedAt: data.comic.updated_at,
                          ),
                          const SizedBox(height: 5),
                          DescriptionBox(description: data.comic.description),
                          const SizedBox(height: 5),
                          ChaptersList(
                            chapters: chapters,
                            startRead: _startRead,
                          ),
                          const SizedBox(height: 5),
                          TitleBox(
                            title: '相关推荐',
                            builder: (context) {
                              return Recommendation(id: widget.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  _ => const Center(child: CircularProgressIndicator()),
                };
              },
            ),
          ),
        );
      },
    );
  }
}