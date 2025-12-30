import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/providers/search_provider.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/search/item.dart';
import 'package:provider/provider.dart';

class HotSearchWords extends StatefulWidget {
  const HotSearchWords({super.key, required this.isRouteAnimationCompleted});

  final bool isRouteAnimationCompleted;

  @override
  State<HotSearchWords> createState() => _HotSearchWordsState();
}

class _HotSearchWordsState extends State<HotSearchWords> with RequestMixin {
  final _handler = fetchHotSearchWords.useRequest(
    onSuccess: (data) {
      Log.info('Fetch hot search words success', data.toString());
    },
    onError: (e) {
      Log.error('Fetch hot search words error', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150),
      child: switch (_handler.state) {
        Success(:final data) => Column(
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
              children: data.keywords
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
        Error(error: final _) => Center(
          child: IconButton(
            onPressed: _handler.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
