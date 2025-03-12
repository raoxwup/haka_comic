import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Comics extends StatefulWidget {
  const Comics({super.key, this.t, this.c, this.a, this.ct, this.ca});

  // Tag
  final String? t;

  // 分类
  final String? c;

  // 作者
  final String? a;

  // 汉化组
  final String? ct;

  // 上传者
  final String? ca;

  @override
  State<Comics> createState() => _ComicsState();
}

class _ComicsState extends State<Comics> {
  final ComicSortType sortType = ComicSortType.dd;
  final int page = 1;

  final handler = fetchComics.useRequest(
    onSuccess: (data, _) {
      Log.info("Fetch comics success", data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comics failed', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    handler.run(ComicsPayload(c: widget.c, s: sortType, page: page));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.c ?? widget.t ?? widget.a ?? widget.ct ?? widget.ca ?? '漫画',
        ),
      ),
      body: BasePage(
        isLoading: handler.isLoading,
        onRetry: handler.refresh,
        error: handler.error,
        child: Center(child: Text(widget.c ?? "")),
      ),
    );
  }
}
