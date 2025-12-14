import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/providers/user_provider.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comments/thumb_up.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class Comments extends StatefulWidget {
  const Comments({super.key});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> with AutoRegisterHandlerMixin {
  late final _handler = fetchPersonalComments.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch personal comments success', data.toString());
      if (!mounted) return;
      setState(() {
        _comments.addAll(data.comments.docs);
        hasMore = data.comments.pages > page;
      });
    },
    onError: (e, _) {
      Log.error('Fetch personal comments error', e);
    },
  );

  final List<PersonalComment> _comments = [];
  final ScrollController _scrollController = ScrollController();
  int page = 1;
  bool hasMore = true;
  bool isLoading = false;

  void _onScroll() {
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * 0.9 &&
        hasMore &&
        !isLoading) {
      isLoading = true;
      _loadMore(page + 1).whenComplete(() => isLoading = false);
    }
  }

  Future<void> _loadMore(int page) async {
    setState(() {
      this.page = page;
    });
    await _handler.run(page);
  }

  void _onRetry() {
    setState(() {
      _comments.clear();
      hasMore = true;
      page = 1;
    });
    _handler.run(1);
  }

  @override
  void initState() {
    super.initState();

    _handler.run(page);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.userSelector((p) => p.userHandler.state.data!.user);
    return RouteAwarePageWrapper(
      shouldRebuildOnCompleted: false,
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(title: const Text('我的评论')),
          body: _handler.error != null ? _buildError() : _buildPage(user),
        );
      },
    );
  }

  Widget _buildPage(User user) {
    if (!_handler.isLoading && _comments.isEmpty) {
      return _buildEmpty();
    } else {
      return _buildList(user);
    }
  }

  Widget _buildList(User user) {
    return ListView.separated(
      controller: _scrollController,
      itemBuilder: (_, index) {
        if (index >= _comments.length) return _buildLoader();
        final item = _comments[index];
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                user.avatar == null
                    ? Card(
                        clipBehavior: Clip.hardEdge,
                        elevation: 0,
                        shape: const CircleBorder(),
                        child: Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(5),
                          child: Image.asset('assets/images/user.png'),
                        ),
                      )
                    : BaseImage(
                        url: user.avatar!.url,
                        width: 64,
                        height: 64,
                        shape: const CircleBorder(),
                      ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          InkWell(
                            onTap: () => context.push(
                              '/personal_sub_comments',
                              extra: {'comment': item, 'user': user},
                            ),
                            borderRadius: BorderRadius.circular(99),
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
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 5),
      itemCount: _comments.length + 1,
    );
  }

  Widget _buildLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: hasMore
            ? CircularProgressIndicator(
                constraints: BoxConstraints.tight(const Size(28, 28)),
                strokeWidth: 3,
              )
            : Text('没有更多数据了', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Empty(imageUrl: 'assets/images/icon_no_comment.png');
  }

  Widget _buildError() {
    return ErrorPage(
      errorMessage: getTextBeforeNewLine(_handler.error.toString()),
      onRetry: _onRetry,
    );
  }

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];
}
