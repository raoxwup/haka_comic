import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comments/comment_input.dart';
import 'package:haka_comic/views/comments/comment_list.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.id});

  final String id;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage>
    with RequestMixin, PaginationMixin {
  int _page = 1;

  late final handler = fetchComicComments.useRequest(
    defaultParams: CommentsPayload(id: widget.id, page: _page),
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
  Future<void> loadMore() async {
    final pages = handler.state.data?.comments.pages ?? 1;
    if (_page >= pages) return;
    await handler.run(CommentsPayload(id: widget.id, page: ++_page));
  }

  void _refresh() {
    _page = 1;
    handler.mutate(CommentsResponse.empty);
    handler.run(CommentsPayload(id: widget.id, page: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('评论')),
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
                    commentsCount: e.totalComments ?? e.commentsCount,
                  ),
                )
                .toList(),
            loading: handler.state.loading,
            onBottomBoxTap: _showCommentInput,
            onCommentIconTap: (index) => context.push(
              '/comments/${widget.id}/sub_comments',
              extra: data.comments.docs[index],
            ),
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

  void _showCommentInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) => CommentInput(
        id: widget.id,
        handler: sendComment.useRequest(
          manual: true,
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
