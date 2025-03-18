import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.id});

  final String id;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final handler = fetchComicComments.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic comments success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic comments error', e);
    },
  );

  int page = 1;

  void _update() => setState(() {});

  @override
  void initState() {
    handler.run(CommentsPayload(id: widget.id, page: page));

    handler.addListener(_update);

    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = handler.data?.comments.docs ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('评论')),
      body: BasePage(
        isLoading: handler.isLoading,
        onRetry: handler.refresh,
        error: handler.error,
        child: data.isEmpty ? _buildEmpty() : _buildList(data),
      ),
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
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = data[index];
        final time = getFormattedDate(item.created_at);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          child: Row(
            spacing: 8,
            children: [
              Align(
                child: BaseImage(
                  url: item.user.avatar?.url ?? '',
                  width: 40,
                  height: 40,
                  shape: CircleBorder(),
                ),
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
                          item.user.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      item.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    // Row(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      itemCount: data.length,
    );
  }
}
