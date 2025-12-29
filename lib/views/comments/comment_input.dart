import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/button.dart';

class CommentInput extends StatefulWidget {
  const CommentInput({super.key, required this.id, required this.handler});

  final String id;

  final RequestHandlerWithParams<void, SendCommentPayload> handler;

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> with RequestMixin {
  late final _handler = widget.handler;
  final _commentController = TextEditingController();

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _commentController.text;
    final bottom = context.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 5 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          TextField(
            minLines: 3,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '评论',
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: context.colorScheme.surfaceContainerHighest,
            ),
            controller: _commentController,
            onChanged: (_) => setState(() {}),
          ),
          Row(
            spacing: 5,
            children: [
              const Spacer(),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('取消', style: context.textTheme.bodyMedium),
              ),
              Button.text(
                isLoading: _handler.state.loading,
                onPressed: content.isEmpty
                    ? null
                    : () {
                        _handler.run(
                          SendCommentPayload(id: widget.id, content: content),
                        );
                      },
                child: const Text('发送'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
