import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comments/comment_input.dart';
import 'package:haka_comic/views/comments/thumb_up.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.id});

  final String id;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late final handler = fetchComicComments.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic comments success', data.toString());
      setState(() {
        _comments.addAll(data.comments.docs);
        _hasMore = data.comments.pages > _page;
      });
    },
    onError: (e, _) {
      Log.error('Fetch comic comments error', e);
    },
  );

  final ScrollController _scrollController = ScrollController();
  final List<Comment> _comments = [];
  bool _hasMore = true;
  int _page = 1;

  final double bottomBoxHeight = 40;

  void _update() => setState(() {});

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (handler.isLoading || !_hasMore) return;
    handler.run(CommentsPayload(id: widget.id, page: ++_page));
  }

  void _refresh() {
    setState(() {
      _comments.clear();
      _hasMore = true;
      _page = 1;
    });
    handler.run(CommentsPayload(id: widget.id, page: 1));
  }

  @override
  void initState() {
    handler.addListener(_update);

    handler.run(CommentsPayload(id: widget.id, page: _page));

    _scrollController.addListener(_onScroll);

    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();

    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwarePageWrapper(
      shouldRebuildOnCompleted: false,
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(title: const Text('评论')),
          body:
              handler.error != null
                  ? _buildError()
                  : Stack(children: [_buildPage(), _buildBottom()]),
        );
      },
    );
  }

  Widget _buildPage() {
    if (!handler.isLoading && _comments.isEmpty) {
      return _buildEmpty();
    } else {
      return _buildList(_comments);
    }
  }

  Widget _buildBottom() {
    final bottom = context.bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
          color: context.colorScheme.surface,
        ),
        child: InkWell(
          onTap: _showCommentInput,
          child: Container(
            height: bottomBoxHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(99)),
              color: context.colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Text('评论', style: context.textTheme.bodySmall),
                const Spacer(),
                const Icon(Icons.send, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ErrorPage(
      errorMessage: getTextBeforeNewLine(handler.error.toString()),
      onRetry: _refresh,
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        children: [Empty(imageUrl: 'assets/images/icon_no_comment.png')],
      ),
    );
  }

  Widget _buildList(List<Comment> data) {
    final bottom = context.bottom;
    return ListView.separated(
      padding: EdgeInsets.only(bottom: 8 + 8 + bottom + bottomBoxHeight),
      controller: _scrollController,
      separatorBuilder: (context, index) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        if (index >= data.length) return _buildLoader();

        final item = data[index];
        final time = getFormattedTime(item.created_at);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          child: Row(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: InkWell(
                  onTap: () => showCreator(context, item.user),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child:
                      item.user.avatar == null
                          ? Card(
                            clipBehavior: Clip.hardEdge,
                            elevation: 0,
                            shape: const CircleBorder(),
                            child: Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(5),
                              child: Image.asset('assets/images/user.png'),
                            ),
                          )
                          : BaseImage(
                            url: item.user.avatar!.url,
                            width: 40,
                            height: 40,
                            shape: const CircleBorder(),
                          ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(
                      item.user.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(time, style: context.textTheme.bodySmall),
                    Text(item.content, style: context.textTheme.bodyMedium),
                    Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ThumbUp(
                          isLiked: item.isLiked,
                          likesCount: item.likesCount,
                          id: item.id,
                        ),
                        InkWell(
                          onTap:
                              () => context.push('/sub_comments', extra: item),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(99),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              spacing: 5,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.comment_outlined, size: 16),
                                Text(
                                  (item.totalComments ?? item.commentsCount)
                                      .toString(),
                                  style: context.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      itemCount: data.length + 1,
    );
  }

  Widget _buildLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child:
            _hasMore
                ? CircularProgressIndicator(
                  constraints: BoxConstraints.tight(const Size(28, 28)),
                  strokeWidth: 3,
                )
                : Text('没有更多数据了', style: context.textTheme.bodySmall),
      ),
    );
  }

  void _showCommentInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      builder:
          (context) => CommentInput(
            id: widget.id,
            handler: sendComment.useRequest(
              onSuccess: (data, _) {
                Log.info('Send comment success', 'comment');
                _refresh();
                context.pop();
              },
              onError: (e, _) {
                Log.error('Send comment error', e);
                Toast.show(message: '评论失败');
              },
            ),
          ),
    );
  }
}
