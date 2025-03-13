import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_page.dart';

class ComicDetails extends StatefulWidget {
  const ComicDetails({super.key, required this.id});

  final String id;

  @override
  State<ComicDetails> createState() => _ComicDetailsState();
}

class _ComicDetailsState extends State<ComicDetails> {
  final handler = fetchComicDetails.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch comic details', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comic details error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    handler.run(widget.id);

    handler.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    handler.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = handler.data?.comic;

    return Scaffold(
      appBar: AppBar(title: const Text('漫画详情')),
      body: BasePage(
        isLoading: handler.isLoading,
        onRetry: handler.refresh,
        error: handler.error,
        child: Text(data?.title ?? ''),
      ),
    );
  }
}
