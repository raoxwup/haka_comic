import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/toast.dart';

class LikedAction extends StatefulWidget {
  const LikedAction({super.key, required this.id, required this.isLiked});

  final String id;

  final bool isLiked;

  @override
  State<LikedAction> createState() => _LikedActionState();
}

class _LikedActionState extends State<LikedAction>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late AnimationController _controller;
  late Animation<double> _animation;
  late final handler = likeComic.useRequest(
    onSuccess: (data, _) {
      Log.info('Like comic success', data.action);
    },
    onError: (e, _) {
      Log.error('Like comic error', e);
      Toast.show(message: '点赞失败');
      setState(() {
        _isLiked = !_isLiked;
      });
    },
  );

  @override
  void initState() {
    super.initState();

    _isLiked = widget.isLiked;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    setState(() {
      _isLiked = !_isLiked;
    });
    _controller.forward(from: 0);

    handler.run(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: ScaleTransition(
        scale: _animation,
        child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
      ),
      shape: const StadiumBorder(),
      label: const Text('点赞'),
      onPressed: _handlePress,
    );
  }
}
