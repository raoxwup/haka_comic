import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:haka_comic/widgets/tag.dart';

class HotSearchWords extends StatefulWidget {
  const HotSearchWords({super.key, required this.isRouteAnimationCompleted});

  final bool isRouteAnimationCompleted;

  @override
  State<HotSearchWords> createState() => _HotSearchWordsState();
}

class _HotSearchWordsState extends State<HotSearchWords> {
  final _handler = fetchHotSearchWords.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch hot search words success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch hot search words error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    super.initState();
    _handler
      ..addListener(_update)
      ..run();
  }

  @override
  void dispose() {
    super.dispose();
    _handler
      ..removeListener(_update)
      ..dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = _handler.data?.keywords ?? [];
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 150),
      child: BasePage(
        error: _handler.error,
        isLoading: _handler.isLoading || !widget.isRouteAnimationCompleted,
        onRetry: _handler.refresh,
        errorBuilder:
            (context) => Center(
              child: IconButton(
                onPressed: _handler.refresh,
                icon: Icon(Icons.refresh),
              ),
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('热门搜索', style: context.textTheme.titleMedium),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children:
                  words
                      .map(
                        (e) => Tag(
                          tag: e,
                          size: TagSize.medium,
                          color: context.colorScheme.surfaceContainerHighest,
                          onPressed:
                              () => context.push('/search_comics?keyword=$e'),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
