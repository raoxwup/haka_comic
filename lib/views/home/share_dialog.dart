import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/toast.dart';

class ShareDialog extends StatefulWidget {
  const ShareDialog({super.key});

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final _controller = TextEditingController();

  late final _handler = fetchComicIdByShareId.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic id by share id success', data.toString());
      context.push('/details/$data');
      context.pop();
    },
    onError: (e, _) {
      Log.error('Fetch comic id by share id error', e);
      Toast.show(message: '获取漫画失败');
    },
  );

  void _update() => setState(() {});

  Future<void> _getClipboardData() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text!.startsWith('PICA')) {
        _controller.text = data.text!;
      }
    } catch (e) {
      Log.error('Get clipboard data error', e);
    }
  }

  @override
  void initState() {
    super.initState();
    _handler
      ..addListener(_update)
      ..isLoading = false;
    _getClipboardData();
  }

  @override
  void dispose() {
    _handler.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      title: const Text('漫画ID'),
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        Button.filled(
          onPressed: () {
            final shareId = _controller.text;
            if (shareId.isEmpty || !shareId.contains('PICA')) {
              Toast.show(message: '请输入正确的分享ID');
              return;
            }
            final id = shareId.split('PICA')[1];
            _handler.run(id);
          },
          isLoading: _handler.isLoading,
          child: const Text('查看'),
        ),
      ],
    );
  }
}
