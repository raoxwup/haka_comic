import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comments/comment_icon.dart';
import 'package:haka_comic/views/comments/comment_list_footer.dart';
import 'package:haka_comic/views/comments/thumb_up.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:haka_comic/widgets/ui_avatar.dart';

class Comments extends StatefulWidget {
  const Comments({super.key});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments>
    with RequestMixin, PaginationMixin {
  int page = 1;
  late final _handler = fetchPersonalComments.useRequest(
    defaultParams: page,
    onSuccess: (data, _) {
      Log.info('Fetch personal comments success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch personal comments error', e);
    },
    reducer: (prev, current) {
      if (prev == null) return current;
      return current.copyWith.comments(
        docs: [...prev.comments.docs, ...current.comments.docs],
      );
    },
  );

  @override
  bool get pagination => false;

  @override
  Future<void> loadMore() async {
    final pages = _handler.state.data?.comments.pages ?? 1;
    if (page >= pages) return;
    await _handler.run(++page);
  }

  void _onRetry() {
    page = 1;
    _handler.mutate(PersonalCommentsResponse.empty);
    _handler.run(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.userSelector((p) => p.userHandler.state.data!.user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的评论'),
        leading: BackButton(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).maybePop(),
        ),
      ),
      body: switch (_handler.state) {
        RequestState(:final data) when data != null => SafeArea(
          child: _buildList(user, data.comments.docs),
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _onRetry,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildList(User user, List<PersonalComment> comments) {
    return ListView.separated(
      controller: scrollController,
      itemBuilder: (_, index) {
        if (index >= comments.length) {
          return CommentListFooter(loading: _handler.state.loading);
        }

        final item = comments[index];
        final time = getFormattedTime(item.created_at);

        return InkWell(
          onTap: () {
            if (item.comic == null) {
              Toast.show(message: "暂不支持跳转游戏");
              return;
            }
            context.push('/details/${item.comic!.id}');
          },
          child: Padding(
            padding: const .symmetric(vertical: 8, horizontal: 15),
            child: Row(
              spacing: 8,
              crossAxisAlignment: .start,
              children: [
                UiAvatar(source: user.avatar, size: 64),
                Expanded(
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    spacing: 5,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(time, style: context.textTheme.bodySmall),
                        ],
                      ),
                      Text(item.content, style: context.textTheme.bodyMedium),
                      Text(
                        '>> ${item.comic?.title ?? item.game?.title ?? ''}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          const Spacer(),
                          ThumbUp(
                            id: item.uid,
                            likesCount: item.likesCount,
                            isLiked: item.isLiked,
                          ),
                          CommentIcon(
                            onTap: () => context.push(
                              '/personal_comments/sub_comments',
                              extra: item.toComment(user),
                            ),
                            icon: const Icon(Icons.comment_outlined, size: 16),
                            count: item.totalComments ?? item.commentsCount,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 5),
      itemCount: comments.length + 1,
    );
  }

  @override
  List<RequestHandler> registerHandler() => [_handler];
}
