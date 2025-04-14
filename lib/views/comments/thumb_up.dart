import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';

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

class _ThumbUpState extends State<ThumbUp> {
  late final AsyncRequestHandler1<ActionResponse, String> _handler;

  bool _isLiked = false;

  int _likesCount = 0;

  void _update() => setState(() {});

  @override
  void initState() {
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;

    _handler = likeComment.useRequest(
      onSuccess: (data, _) {
        Log.info('Like comment success', data.action);
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      },
      onError: (e, _) {
        Log.error('Like comment error', e);
        showSnackBar('点赞失败');
      },
    );

    _handler.addListener(_update);

    _handler.isLoading = false;

    super.initState();
  }

  @override
  void dispose() {
    _handler
      ..removeListener(_update)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _handler.run(widget.id);
      },
      borderRadius: BorderRadius.all(Radius.circular(99)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          spacing: 5,
          mainAxisSize: MainAxisSize.min,
          children: [
            _handler.isLoading
                ? CircularProgressIndicator(
                  constraints: BoxConstraints.tight(const Size(12, 12)),
                  strokeWidth: 1,
                  color: context.textTheme.bodySmall?.color,
                )
                : Icon(
                  _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                ),
            Text(_likesCount.toString(), style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
