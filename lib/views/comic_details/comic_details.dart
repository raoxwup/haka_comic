import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/tag_block_helper.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/mixin/blocked_words.dart';
import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/download_manager.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/database/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comic_details/chapters_list.dart';
import 'package:haka_comic/views/comic_details/collect_action.dart';
import 'package:haka_comic/views/comic_details/comic_share_id.dart';
import 'package:haka_comic/views/comic_details/creator.dart';
import 'package:haka_comic/views/comic_details/liked_action.dart';
import 'package:haka_comic/views/comic_details/icon_text.dart';
import 'package:haka_comic/views/comic_details/recommendation.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:provider/provider.dart';

class ComicDetails extends StatefulWidget {
  const ComicDetails({super.key, required this.id});

  final String id;

  @override
  State<ComicDetails> createState() => _ComicDetailsState();
}

class _ComicDetailsState extends State<ComicDetails>
    with AutoRegisterHandlerMixin {
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
  late final chaptersHandler = fetchChapters.useRequest(
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
  List<AsyncRequestHandler> registerHandler() => [handler, chaptersHandler];

  final ValueNotifier<bool> _showTitleNotifier = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final double _scrollThreshold = 80;
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

    handler.run(widget.id);
    chaptersHandler.run(widget.id);

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

    super.dispose();
  }

  /// 进入阅读
  void _startRead({String? chapterId, int? pageNo}) {
    final data = handler.data?.comic;
    final chapter = _chapters.firstWhere(
      (element) => element.id == chapterId,
      orElse: () => _chapters.first,
    );
    context.read<ReaderProvider>().initialize(
      id: widget.id,
      title: data!.title,
      chapters: _chapters,
      currentChapter: chapter,
      pageNo: pageNo,
    );
    context.push('/reader');
  }

  @override
  Widget build(BuildContext context) {
    final data = handler.data?.comic;
    final bottom = context.bottom;

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
                    leadingIcon: const Icon(Icons.copy),
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
          body: BasePage(
            isLoading:
                handler.isLoading || chaptersHandler.isLoading || !completed,
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
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                ),
                                child: value != null
                                    ? FilledButton.tonalIcon(
                                        onPressed: () => _startRead(),
                                        label: const Text('从头开始'),
                                      )
                                    : FilledButton(
                                        onPressed: () => _startRead(),
                                        child: const Text('开始阅读'),
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
                                    onPressed: () => _startRead(
                                      chapterId: value.chapterId,
                                      pageNo: value.pageNo,
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
                  const SizedBox(height: 5),
                  _buildDescription(data),
                  const SizedBox(height: 5),
                  ChaptersList(
                    chapters: chaptersHandler.data ?? [],
                    startRead: _startRead,
                  ),
                  const SizedBox(height: 5),
                  _buildRecommendation(data),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendation(Comic? data) {
    return TitleBox(
      title: '相关推荐',
      builder: (context) {
        return Recommendation(id: widget.id);
      },
    );
  }

  Widget _buildTitle(Comic? data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        BaseImage(url: data?.thumb.url ?? '', height: 170, width: 115),
        Expanded(
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data?.title ?? '',
                style: context.textTheme.titleMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              InfoRow(
                onTap: (data?.author == null || data!.author.isEmpty)
                    ? null
                    : () => context.push('/comics?a=${data.author}'),
                data: data?.author,
                icon: Icons.person,
              ),
              InfoRow(
                onTap: (data?.chineseTeam == null || data!.chineseTeam.isEmpty)
                    ? null
                    : () => context.push('/comics?ct=${data.chineseTeam}'),
                data: data?.chineseTeam,
                icon: Icons.translate,
              ),
              ComicShareId(id: widget.id),
              Row(
                spacing: 10,
                children: [
                  IconText(
                    icon: const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.red,
                    ),
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
                  avatar: const Icon(Icons.menu_book),
                  shape: const StadiumBorder(),
                  label: const Text('从头开始'),
                  onPressed: () => _startRead(),
                ),
              if (UiMode.notM1(context) && value != null)
                ActionChip(
                  avatar: const Icon(Icons.bookmark),
                  shape: const StadiumBorder(),
                  label: const Text('继续阅读'),
                  onPressed: () => _startRead(
                    chapterId: value.chapterId,
                    pageNo: value.pageNo,
                  ),
                ),
              LikedAction(isLiked: data?.isLiked ?? false, id: widget.id),
              CollectAction(
                isFavorite: data?.isFavourite ?? false,
                id: widget.id,
              ),
              ActionChip(
                avatar: const Icon(Icons.comment),
                shape: const StadiumBorder(),
                label: Text('${data?.commentsCount}'),
                onPressed: data?.allowComment ?? true
                    ? () {
                        context.push('/comments/${widget.id}');
                      }
                    : null,
              ),
              ActionChip(
                avatar: const Icon(Icons.download),
                shape: const StadiumBorder(),
                label: const Text('下载'),
                onPressed: () {
                  context.push(
                    '/downloader',
                    extra: {
                      'chapters': _chapters,
                      'downloadComic': DownloadComic(
                        id: widget.id,
                        title: data?.title ?? '',
                        cover: data?.thumb.url ?? '',
                      ),
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescription(Comic? data) {
    return TitleBox(
      title: '简介',
      builder: (context) {
        return Text(
          data?.description ?? '暂无简介',
          style: context.textTheme.bodyMedium,
        );
      },
    );
  }

  Future<void> _onTagLongPress(String tag) async {
    final helper = TagBlockHelper();
    final contains = await helper.contains(tag);
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(contains ? '取消屏蔽' : '屏蔽'),
            content: Text(
              contains ? '「$tag」已被屏蔽，确定要取消对它的屏蔽吗？' : '确定要屏蔽「$tag」吗？',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  context.pop();
                  contains
                      ? await helper.delete(tag)
                      : await helper.insert(tag);
                  BlockedStream.notify();
                  Toast.show(message: contains ? '已取消屏蔽「$tag」' : '已屏蔽「$tag」');
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildTags(Comic? data, String type) {
    final List<String> tags =
        (type == '标签' ? data?.tags : data?.categories) ?? [];
    final name = type == '标签' ? 't' : 'c';
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: context.colorScheme.errorContainer,
          ),
          child: Text(
            '$type : ',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        ...tags.map(
          (e) => InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push('/comics?$name=$e'),
            onLongPress: type == '标签' ? () => _onTagLongPress(e) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.colorScheme.primaryContainer.withValues(
                  alpha: 0.45,
                ),
              ),
              child: Text(
                e,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
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
            ? const SizedBox.shrink()
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
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

class TitleBox extends StatelessWidget {
  const TitleBox({
    super.key,
    required this.title,
    required this.builder,
    this.actions = const [],
  });

  final String title;
  final WidgetBuilder builder;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(title, style: context.textTheme.titleMedium),
            const Spacer(),
            ...actions,
          ],
        ),
        Builder(builder: builder),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.data,
    this.onTap,
    required this.icon,
  });

  final String? data;
  final void Function()? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(icon, size: 14, color: context.colorScheme.primary),
          Expanded(
            child: Text(
              data ?? '',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
