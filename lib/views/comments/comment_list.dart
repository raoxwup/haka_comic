import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/comments/comment_icon.dart';
import 'package:haka_comic/views/comments/comment_list_footer.dart';
import 'package:haka_comic/views/comments/thumb_up.dart';
import 'package:haka_comic/widgets/ui_avatar.dart';

class SourceItem {
  final String createdAt;

  final String content;

  final Creator user;

  final String id;

  final bool isLiked;

  final int likesCount;

  final int commentsCount;

  const SourceItem({
    required this.createdAt,
    required this.content,
    required this.user,
    required this.id,
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
  });
}

const kBottomBoxHeight = 40.0;

class CommentList extends StatelessWidget {
  const CommentList({
    super.key,
    this.topBuilder,
    required this.scrollController,
    required this.data,
    required this.loading,
    this.onCommentIconTap,
    this.onBottomBoxTap,
  });

  final WidgetBuilder? topBuilder;

  final ScrollController scrollController;

  final List<SourceItem> data;

  final bool loading;

  final void Function(int)? onCommentIconTap;

  final VoidCallback? onBottomBoxTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (topBuilder != null) topBuilder!(context),
        Expanded(
          child: ListView.separated(
            padding: .zero,
            controller: scrollController,
            separatorBuilder: (context, index) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              if (index >= data.length) {
                return CommentListFooter(loading: loading);
              }

              final item = data[index];
              final time = getFormattedTime(item.createdAt);

              return Padding(
                padding: const .symmetric(vertical: 8, horizontal: 15),
                child: Row(
                  spacing: 8,
                  crossAxisAlignment: .start,
                  children: [
                    Align(
                      alignment: .topCenter,
                      child: InkWell(
                        onTap: () => showCreator(context, item.user),
                        borderRadius: .circular(8),
                        child: UiAvatar(source: item.user.avatar, size: 40),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        spacing: 5,
                        children: [
                          Text(
                            item.user.name,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: .bold,
                            ),
                            maxLines: 1,
                            overflow: .ellipsis,
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
                              if (onCommentIconTap != null)
                                CommentIcon(
                                  onTap: () => onCommentIconTap!.call(index),
                                  icon: const Icon(
                                    Icons.comment_outlined,
                                    size: 16,
                                  ),
                                  count: item.commentsCount,
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
          ),
        ),
        if (onBottomBoxTap != null)
          Container(
            padding: const .symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              color: context.colorScheme.surface,
            ),
            child: InkWell(
              onTap: onBottomBoxTap,
              child: Container(
                height: kBottomBoxHeight,
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
      ],
    );
  }
}
