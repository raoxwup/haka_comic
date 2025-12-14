import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/providers/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/views/search/item.dart';
import 'package:haka_comic/widgets/base_page.dart';
import 'package:provider/provider.dart';

class HotSearchWords extends StatefulWidget {
  const HotSearchWords({super.key, required this.isRouteAnimationCompleted});

  final bool isRouteAnimationCompleted;

  @override
  State<HotSearchWords> createState() => _HotSearchWordsState();
}

class _HotSearchWordsState extends State<HotSearchWords>
    with AutoRegisterHandlerMixin {
  final _handler = fetchHotSearchWords.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch hot search words success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch hot search words error', e);
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  void initState() {
    super.initState();
    _handler.run();
  }

  @override
  Widget build(BuildContext context) {
    final words = _handler.data?.keywords ?? [];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150),
      child: BasePage(
        error: _handler.error,
        isLoading: _handler.isLoading || !widget.isRouteAnimationCompleted,
        onRetry: _handler.refresh,
        errorBuilder: (context) => Center(
          child: IconButton(
            onPressed: _handler.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              spacing: 5,
              children: [
                Text(
                  '热门搜索',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: words
                  .map(
                    (e) => Item(
                      title: e,
                      onTap: () {
                        context.read<SearchProvider>().add(e);
                        context.push('/search_comics?keyword=$e');
                      },
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
