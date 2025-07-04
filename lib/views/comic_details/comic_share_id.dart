import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/comic_details/comic_details.dart';
import 'package:haka_comic/widgets/toast.dart';

class ComicShareId extends StatefulWidget {
  const ComicShareId({super.key, required this.id});

  /// 漫画id
  final String id;

  @override
  State<ComicShareId> createState() => _ComicShareIdState();
}

class _ComicShareIdState extends State<ComicShareId>
    with AutoRegisterHandlerMixin {
  final _handler = fetchComicShareId.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic share id success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic share id error', e);
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  void initState() {
    super.initState();
    _handler.run(widget.id);
  }

  void copy() async {
    await Clipboard.setData(ClipboardData(text: 'PICA${_handler.data}'));
    Toast.show(message: '已复制');
  }

  @override
  Widget build(BuildContext context) {
    final String id = _handler.data?.toString() ?? '加载中...';
    return InfoRow(
      onTap: _handler.data == null ? null : copy,
      icon: Icons.share,
      data: id,
    );
  }
}
