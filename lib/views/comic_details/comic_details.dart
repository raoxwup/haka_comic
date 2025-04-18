import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/read_record_helper.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comic_details/chapters_list.dart';
import 'package:haka_comic/views/comic_details/collect_action.dart';
import 'package:haka_comic/views/comic_details/comic_share_id.dart';
import 'package:haka_comic/views/comic_details/creator.dart';
import 'package:haka_comic/views/comic_details/liked_action.dart';
import 'package:haka_comic/views/comic_details/icon_text.dart';
import 'package:haka_comic/views/comic_details/recommendation.dart';
import 'package:haka_comic/widgets/tag.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';

class ComicDetails extends StatefulWidget {
  const ComicDetails({super.key, required this.id});

  final String id;

  @override
  State<ComicDetails> createState() => _ComicDetailsState();
}

class _ComicDetailsState extends State<ComicDetails> {
  /// 漫画详情
  final handler = fetchComicDetails.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic details', data.toString());
      HistoryHelper().insert(data.comic);
    },
    onError: (e, _) {
      Log.error('Fetch comic details error', e);
    },
  );

  /// 漫画章节
  late final AsyncRequestHandler1<List<Chapter>, String> chaptersHandler;

  final ValueNotifier<bool> _showTitleNotifier = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final double _scrollThreshold = 80;
  final _helper = ReadRecordHelper();

  // 阅读记录
  final ValueNotifier<ComicReadRecord?> _readRecordNotifier = ValueNotifier(
    null,
  );

  List<Chapter> _chapters = [];

  void _update() => setState(() {});

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
    handler.addListener(_update);

    _scrollController.addListener(_handleScroll);

    _updateReadRecord();

    _helper.addListener(_updateReadRecord);

    chaptersHandler = fetchChapters.useRequest(
      onSuccess: (data, _) {
        Log.info('Fetch chapters success', data.toString());
        // 哔咔最新的排在最前面
        _chapters = data.reversed.toList();
      },
      onError: (e, _) {
        Log.error('Fetch chapters error', e);
      },
    )..addListener(_update);

    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();

    chaptersHandler
      ..removeListener(_update)
      ..dispose();

    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    _helper.removeListener(_updateReadRecord);

    super.dispose();
  }

  /// 进入阅读
  void _startRead(String chapterId, [int pageNo = 0]) {
    final data = handler.data?.comic;
    context.push(
      '/reader/${widget.id}/$chapterId/$pageNo/${data?.title}',
      extra: _chapters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = handler.data?.comic;
    final bottom = context.bottom;

    return RouteAwarePageWrapper(
      onRouteAnimationCompleted: () {
        handler.run(widget.id);
        chaptersHandler.run(widget.id);
      },
      child: Scaffold(
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
              builder:
                  (context, controller, widget) => IconButton(
                    icon: Icon(Icons.more_horiz),
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
                  leadingIcon: Icon(Icons.copy),
                  child: const Text('复制标题'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: data?.title ?? ''),
                    );
                    showSnackBar('标题复制成功!');
                  },
                ),
              ],
            ),
          ],
        ),
        body: BasePage(
          isLoading: handler.isLoading || chaptersHandler.isLoading,
          onRetry: () {
            handler.refresh();
            chaptersHandler.refresh();
          },
          error: handler.error ?? chaptersHandler.error,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + 20),
            child: Column(
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(data),
                _buildTags(data, '分类'),
                _buildTags(data, '标签'),
                _buildActions(data),
                if (UiMode.m1(context))
                  ValueListenableBuilder(
                    valueListenable: _readRecordNotifier,
                    builder: (context, value, child) {
                      return Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 40),
                              child: ElevatedButton(
                                onPressed: () => _startRead(_chapters.first.id),
                                child: const Text('从头开始'),
                              ),
                            ),
                          ),
                          if (value != null)
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                ),
                                child: FilledButton(
                                  onPressed:
                                      () => _startRead(
                                        value.chapterId,
                                        value.pageNo,
                                      ),
                                  child: const Text('继续阅读'),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                _buildReadRecord(),
                // SizedBox(height: 8),
                const Divider(),
                ComicCreator(
                  creator: data?.creator,
                  updatedAt: data?.updated_at,
                ),
                SizedBox(height: 5),
                _buildDescription(data),
                SizedBox(height: 5),
                ChaptersList(
                  chapters: chaptersHandler.data ?? [],
                  startRead: _startRead,
                ),
                SizedBox(height: 5),
                _buildRecommendation(data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendation(Comic? data) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('相关推荐', style: context.textTheme.titleMedium),
        Recommendation(id: widget.id),
      ],
    );
  }

  Widget _buildTitle(Comic? data) {
    return SizedBox(
      height: 180,
      child: Row(
        spacing: 10,
        children: [
          BaseImage(url: data?.thumb.url ?? '', aspectRatio: 0.7),
          Expanded(
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data?.title ?? '',
                  style: context.textTheme.titleMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                InkWell(
                  onTap:
                      (data?.author == null || data!.author.isEmpty)
                          ? null
                          : () => context.push('/comics?a=${data.author}'),
                  child: Text(
                    '作者: ${data?.author}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
                InkWell(
                  onTap:
                      (data?.chineseTeam == null || data!.chineseTeam.isEmpty)
                          ? null
                          : () =>
                              context.push('/comics?ct=${data.chineseTeam}'),
                  child: Text(
                    '汉化: ${data?.chineseTeam}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
                ComicShareId(id: widget.id),
                Row(
                  spacing: 10,
                  children: [
                    IconText(
                      icon: Icon(Icons.favorite, size: 16, color: Colors.red),
                      text: formatNumber(
                        data?.totalLikes ?? data?.likesCount ?? 0,
                      ),
                    ),
                    IconText(
                      icon: const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.amber,
                      ),
                      text: formatNumber(
                        data?.totalViews ?? data?.viewsCount ?? 0,
                      ),
                    ),
                    IconText(
                      icon: const Icon(
                        Icons.image,
                        size: 16,
                        color: Colors.green,
                      ),
                      text: formatNumber(data?.pagesCount ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Comic? data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder(
        valueListenable: _readRecordNotifier,
        builder: (context, value, child) {
          return Row(
            spacing: 10,
            children: [
              if (UiMode.notM1(context))
                ActionChip(
                  avatar: Icon(Icons.menu_book),
                  shape: StadiumBorder(),
                  label: Text('从头开始'),
                  onPressed: () => _startRead(_chapters.first.id),
                ),
              if (UiMode.notM1(context) && value != null)
                ActionChip(
                  avatar: Icon(Icons.bookmark),
                  shape: StadiumBorder(),
                  label: Text('继续阅读'),
                  onPressed: () => _startRead(value.chapterId, value.pageNo),
                ),
              LikedAction(isLiked: data?.isLiked ?? false, id: widget.id),
              CollectAction(
                isFavorite: data?.isFavourite ?? false,
                id: widget.id,
              ),
              ActionChip(
                avatar: Icon(Icons.comment),
                shape: StadiumBorder(),
                label: Text('${data?.commentsCount}'),
                onPressed:
                    data?.allowComment ?? true
                        ? () {
                          context.push('/comments/${widget.id}');
                        }
                        : null,
              ),
              ActionChip(
                avatar: Icon(Icons.download),
                shape: StadiumBorder(),
                label: Text('下载'),
                onPressed: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescription(Comic? data) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('简介', style: context.textTheme.titleMedium),
        Text(data?.description ?? '暂无简介', style: context.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildTags(Comic? data, String type) {
    final List<String> tags =
        (type == '标签' ? data?.tags : data?.categories) ?? [];
    final name = type == '标签' ? 't' : 'c';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Tag(tag: '$type:', size: TagSize.medium),
        ...tags.map(
          (e) => Tag(
            tag: e,
            size: TagSize.medium,
            color: context.colorScheme.primaryContainer,
            onPressed: () => context.push('/comics?$name=$e'),
          ),
        ),
      ],
    );
  }

  Widget _buildReadRecord() {
    return ValueListenableBuilder(
      valueListenable: _readRecordNotifier,
      builder: (context, value, child) {
        return value == null
            ? SizedBox.shrink()
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: context.colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                spacing: 10,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark,
                    color: context.colorScheme.primary,
                    size: 18,
                  ),
                  Expanded(
                    child: Text(
                      '上次阅读到${value.chapterTitle} P${value.pageNo + 1}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
      },
    );
  }
}
