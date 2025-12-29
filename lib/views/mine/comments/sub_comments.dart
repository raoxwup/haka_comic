import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart' hide UseRequest1Extensions;
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comments/comment_input.dart';
import 'package:haka_comic/views/comments/comment_list_footer.dart';
import 'package:haka_comic/views/comments/thumb_up.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:haka_comic/widgets/ui_avatar.dart';

class PersonalSubComment extends StatefulWidget {
  const PersonalSubComment({
    super.key,
    required this.comment,
    required this.user,
  });

  final PersonalComment comment;

  final User user;

  @override
  State<PersonalSubComment> createState() => _PersonalSubCommentState();
}

class _PersonalSubCommentState extends State<PersonalSubComment>
    with RequestMixin, PaginationMixin {
  int _page = 1;
  late final handler = fetchSubComments.useRequest(
    defaultParams: SubCommentsPayload(id: widget.comment.uid, page: _page),
    onSuccess: (data, _) {
      Log.info('Fetch comic comments success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic comments error', e);
    },
    reducer: (prev, current) {
      if (prev == null) return current;
      return current.copyWith.comments(
        docs: [...prev.comments.docs, ...current.comments.docs],
      );
    },
  );

  final double bottomBoxHeight = 40;

  @override
  List<RequestHandler> registerHandler() => [handler];

  @override
  Future<void> loadMore() async {
    final pages = handler.state.data?.comments.pages ?? 1;
    if (_page >= pages) return;
    await handler.run(
      SubCommentsPayload(id: widget.comment.uid, page: ++_page),
    );
  }

  void _refresh() {
    _page = 1;
    handler.mutate(SubCommentsResponse.empty);
    handler.run(SubCommentsPayload(id: widget.comment.uid, page: 1));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('子评论')),
        body: switch (handler.state) {
          RequestState(:final data) when data != null => Stack(
            children: [_buildList(data.comments.docs), _buildBottom()],
          ),
          Error(:final error) => ErrorPage(
            errorMessage: error.toString(),
            onRetry: _refresh,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _buildBottom() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const .symmetric(horizontal: 12, vertical: 8),
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
            padding: const .symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: .circular(99),
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

  Widget _buildList(List<SubComment> data) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        _buildSliverToBoxAdapter(),
        SliverPadding(
          padding: EdgeInsets.only(bottom: 8 + 8 + bottomBoxHeight),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              Widget content;
              if (index >= data.length) {
                content = CommentListFooter(loading: handler.state.loading);
              } else {
                final item = data[index];
                final time = getFormattedTime(item.created_at);

                content = Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 15,
                  ),
                  child: Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: InkWell(
                          onTap: () => showCreator(context, item.user),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          child: UiAvatar(source: item.user.avatar, size: 40),
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
                            Text(
                              item.content,
                              style: context.textTheme.bodyMedium,
                            ),
                            Row(
                              spacing: 8,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ThumbUp(
                                  isLiked: item.isLiked,
                                  likesCount: item.likesCount,
                                  id: item.id,
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
              return Column(
                children: [
                  content,
                  if (index < data.length) const SizedBox(height: 5),
                ],
              );
            }, childCount: data.length + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverToBoxAdapter() {
    final comment = widget.comment;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: Column(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: UiAvatar(size: 40, source: widget.user.avatar),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        widget.user.name,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        getFormattedTime(comment.created_at),
                        style: context.textTheme.bodySmall,
                      ),
                      Text(
                        comment.content,
                        style: context.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  void _showCommentInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) => CommentInput(
        id: widget.comment.uid,
        handler: sendReply.useRequest(
          manual: true,
          onSuccess: (data, _) {
            Log.info('Send reply success', 'reply');
            _refresh();
            context.pop();
          },
          onError: (e, _) {
            Log.error('Send reply error', e);
            Toast.show(message: '回复失败');
          },
        ),
      ),
    );
  }
}
