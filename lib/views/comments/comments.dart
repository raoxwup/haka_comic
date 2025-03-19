import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/error_page.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.id});

  final String id;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late final AsyncRequestHandler1<CommentsResponse, CommentsPayload> handler;
  final ScrollController _scrollController = ScrollController();
  final List<Comment> _comments = [];
  bool _hasMore = true;

  int _page = 1;

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

  @override
  void initState() {
    handler = fetchComicComments.useRequest(
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

    handler.run(CommentsPayload(id: widget.id, page: _page));

    handler.addListener(_update);

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
    return Scaffold(
      appBar: AppBar(title: const Text('评论')),
      body:
          handler.error != null
              ? _buildError()
              : Stack(children: [_buildPage(), _buildCommentBox()]),
    );
  }

  Widget _buildPage() {
    if (!handler.isLoading && _comments.isEmpty) {
      return _buildEmpty();
    } else {
      return _buildList(_comments);
    }
  }

  Widget _buildCommentBox() {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, bottom + 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(99),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ErrorPage(
      errorMessage: getTextBeforeNewLine(handler.error.toString()),
      onRetry: handler.refresh,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        spacing: 8,
        children: [
          SizedBox(height: 80),
          Image.asset('assets/images/icon_no_comment.png', width: 200),
          const Text('暂无评论'),
        ],
      ),
    );
  }

  Widget _buildList(List<Comment> data) {
    return ListView.separated(
      controller: _scrollController,
      separatorBuilder: (context, index) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        if (index >= data.length) return _buildLoader();

        final item = data[index];
        final time = getFormattedDate(item.created_at);

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
                            shape: CircleBorder(),
                            child: Container(
                              width: 40,
                              height: 40,
                              padding: EdgeInsets.all(5),
                              child: Image.asset('assets/images/user.png'),
                            ),
                          )
                          : BaseImage(
                            url: item.user.avatar!.url,
                            width: 40,
                            height: 40,
                            shape: CircleBorder(),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(time, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      item.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              spacing: 5,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.isLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  size: 16,
                                ),
                                Text(
                                  item.likesCount.toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              spacing: 5,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment_outlined, size: 16),
                                Text(
                                  (item.totalComments ?? item.commentsCount)
                                      .toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
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
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child:
            _hasMore
                ? CircularProgressIndicator(
                  constraints: BoxConstraints.tight(const Size(28, 28)),
                  strokeWidth: 3,
                )
                : Text('没有更多数据了', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
