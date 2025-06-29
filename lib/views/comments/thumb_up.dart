import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
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

class _ThumbUpState extends State<ThumbUp> with AutoRegisterHandlerMixin {
  late final _handler = likeComment.useRequest(
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

  bool _isLiked = false;

  int _likesCount = 0;

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;

    _handler.isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _handler.run(widget.id);
      },
      borderRadius: const BorderRadius.all(Radius.circular(99)),
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
