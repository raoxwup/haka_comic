import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comments/comment_icon.dart';
import 'package:haka_comic/widgets/toast.dart';

class ThumbUp extends StatefulWidget {
  const ThumbUp({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.id,
  });

  final bool isLiked;

  final int likesCount;

  final String id;

  @override
  State<ThumbUp> createState() => _ThumbUpState();
}

class _ThumbUpState extends State<ThumbUp> with RequestMixin {
  late final _handler = likeComment.useRequest(
    manual: true,
    onSuccess: (data, _) {
      Log.info('Like comment success', data.action);
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    },
    onError: (e, _) {
      Log.error('Like comment error', e);
      Toast.show(message: '点赞失败');
    },
  );

  late bool _isLiked = widget.isLiked;

  late int _likesCount = widget.likesCount;

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    return CommentIcon(
      onTap: () => _handler.run(widget.id),
      count: _likesCount,
      loading: _handler.state.loading,
      icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 16),
    );
  }
}
