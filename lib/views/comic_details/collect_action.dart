import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/toast.dart';

class CollectAction extends StatefulWidget {
  const CollectAction({super.key, required this.id, required this.isFavorite});

  final String id;

  final bool isFavorite;

  @override
  State<CollectAction> createState() => _CollectActionState();
}

class _CollectActionState extends State<CollectAction>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  late AnimationController _controller;
  late Animation<double> _animation;
  late final handler = favoriteComic.useRequest(
    onSuccess: (data, _) {
      Log.info('Favorite comic success', data.action);
    },
    onError: (e, _) {
      Log.error('Favorite comic error', e);
      Toast.show(message: '收藏失败');
      setState(() {
        _isFavorite = !_isFavorite;
      });
    },
  );

  @override
  void initState() {
    super.initState();

    _isFavorite = widget.isFavorite;

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
      _isFavorite = !_isFavorite;
    });
    _controller.forward(from: 0);

    handler.run(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: ScaleTransition(
        scale: _animation,
        child: Icon(_isFavorite ? Icons.star : Icons.star_outline),
      ),
      shape: const StadiumBorder(),
      label: const Text('收藏'),
      onPressed: _handlePress,
    );
  }
}
