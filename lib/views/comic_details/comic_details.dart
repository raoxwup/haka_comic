import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comic_details/chapters_list.dart';
import 'package:haka_comic/views/comic_details/creator.dart';
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
  final handler = fetchComicDetails.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic details', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic details error', e);
    },
  );

  bool _showTitle = false;
  final ScrollController _scrollController = ScrollController();
  final double _scrollThreshold = 80;

  void _update() => setState(() {});

  void _handleScroll() {
    final currentScroll = _scrollController.offset;
    final shouldShow = currentScroll > _scrollThreshold;

    if (shouldShow != _showTitle) {
      setState(() => _showTitle = shouldShow);
    }
  }

  @override
  void initState() {
    handler.run(widget.id);

    handler.addListener(_update);

    _scrollController.addListener(_handleScroll);

    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();

    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = handler.data?.comic;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(data?.title ?? ''),
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
        isLoading: handler.isLoading,
        onRetry: handler.refresh,
        error: handler.error,
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
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('开始阅读'),
                      ),
                    ),
                  ],
                ),
              // SizedBox(height: 8),
              const Divider(),
              ComicCreator(creator: data?.creator, updatedAt: data?.updated_at),
              SizedBox(height: 5),
              _buildDescription(data),
              SizedBox(height: 5),
              _buildChaptersList(data),
              SizedBox(height: 5),
              _buildRecommendation(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChaptersList(Comic? data) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('目录', style: Theme.of(context).textTheme.titleMedium),
        ChaptersList(id: widget.id),
      ],
    );
  }

  Widget _buildRecommendation(Comic? data) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('相关推荐', style: Theme.of(context).textTheme.titleMedium),
        Recommendation(id: widget.id),
      ],
    );
  }

  Widget _buildTitle(Comic? data) {
    return SizedBox(
      height: 160,
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
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '作者: ${data?.author}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '汉化: ${data?.chineseTeam}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    IconText(
                      icon: Icon(Icons.favorite, size: 16),
                      text: '${data?.totalLikes ?? data?.likesCount}',
                    ),
                    IconText(
                      icon: const Icon(Icons.visibility, size: 16),
                      text: '${data?.totalViews ?? data?.viewsCount}',
                    ),
                    IconText(
                      icon: const Icon(Icons.image, size: 16),
                      text: '${data?.pagesCount}',
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
      child: Row(
        spacing: 10,
        children: [
          if (UiMode.notM1(context))
            ActionChip(
              avatar: Icon(Icons.menu_book),
              shape: StadiumBorder(),
              label: Text('开始阅读'),
              onPressed: () {},
            ),
          ActionChip(
            avatar: Icon(Icons.favorite_border),
            shape: StadiumBorder(),
            label: Text('点赞'),
            onPressed: () {},
          ),
          ActionChip(
            avatar: Icon(Icons.star_outline),
            shape: StadiumBorder(),
            label: Text('收藏'),
            onPressed: () {},
          ),
          ActionChip(
            avatar: Icon(Icons.comment),
            shape: StadiumBorder(),
            label: Text('${data?.commentsCount}'),
            onPressed: data?.allowComment ?? true ? () {} : null,
          ),
          ActionChip(
            avatar: Icon(Icons.download),
            shape: StadiumBorder(),
            label: Text('下载'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Comic? data) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('简介', style: Theme.of(context).textTheme.titleMedium),
        Text(
          data?.description ?? '暂无简介',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
            color: Theme.of(context).colorScheme.primaryContainer,
            onPressed: () => context.push('/comics?$name=$e'),
          ),
        ),
      ],
    );
  }
}
