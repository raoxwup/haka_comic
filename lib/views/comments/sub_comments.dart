import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comments/comment_input.dart';
import 'package:haka_comic/views/comments/comment_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:haka_comic/widgets/ui_avatar.dart';

class SubCommentsPage extends StatefulWidget {
  const SubCommentsPage({super.key, required this.comment});

  final Comment comment;

  @override
  State<SubCommentsPage> createState() => _SubCommentsPageState();
}

class _SubCommentsPageState extends State<SubCommentsPage>
    with RequestMixin, PaginationMixin {
  int _page = 1;
  late final handler = fetchSubComments.useRequest(
    defaultParams: SubCommentsPayload(id: widget.comment.id, page: _page),
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

  @override
  List<RequestHandler> registerHandler() => [handler];

  @override
  bool get pagination => false;

  @override
  Future<void> loadMore() async {
    final pages = handler.state.data?.comments.pages ?? 1;
    if (_page >= pages) return;
    await handler.run(SubCommentsPayload(id: widget.comment.id, page: ++_page));
  }

  void _refresh() {
    _page = 1;
    handler.mutate(SubCommentsResponse.empty);
    handler.run(SubCommentsPayload(id: widget.comment.id, page: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('子评论')),
      body: switch (handler.state) {
        RequestState(:final data) when data != null => SafeArea(
          child: CommentList(
            scrollController: scrollController,
            data: data.comments.docs
                .map(
                  (e) => SourceItem(
                    createdAt: e.created_at,
                    content: e.content,
                    user: e.user,
                    id: e.uid,
                    isLiked: e.isLiked,
                    likesCount: e.likesCount,
                    commentsCount: e.totalComments,
                  ),
                )
                .toList(),
            loading: handler.state.loading,
            onBottomBoxTap: _showCommentInput,
            topBuilder: (context) => _buildTop(),
          ),
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _refresh,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildTop() {
    final comment = widget.comment;
    return Padding(
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
                child: InkWell(
                  onTap: () => showCreator(context, comment.user),
                  borderRadius: .circular(8),
                  child: UiAvatar(size: 40, source: comment.user.avatar),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(
                      comment.user.name,
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
                    Text(comment.content, style: context.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
        ],
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
        id: widget.comment.id,
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
