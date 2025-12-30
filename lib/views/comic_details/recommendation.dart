import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class Recommendation extends StatefulWidget {
  const Recommendation({super.key, required this.id});

  final String id;

  @override
  State<Recommendation> createState() => _RecommendationState();
}

class _RecommendationState extends State<Recommendation> with RequestMixin {
  final List<ExtraRecommendComic> _comics = [];

  late final handler = fetchComicRecommendation.useRequest(
    defaultParams: widget.id,
    onSuccess: (data, _) {
      Log.info('Fetch recommendation success', data.toString());
      _comics.addAll(
        data.comics
            .map(
              (e) => ExtraRecommendComic(
                id: e.id,
                title: e.title,
                pic: e.thumb.url,
              ),
            )
            .toList(),
      );
    },
    onError: (e, _) {
      Log.error('Fetch recommendation error', e);
    },
  );

  late final extraHandler = fetchExtraRecommendComics.useRequest(
    defaultParams: widget.id,
    onSuccess: (data, _) {
      Log.info('Fetch extra recommendation success', data.toString());
      _comics.addAll(data);
    },
    onError: (e, _) {
      Log.error('Fetch extra recommendation error', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [handler, extraHandler];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Builder(
        builder: (context) {
          if (handler.state case Loading()) {
            return const Center(child: CircularProgressIndicator());
          }

          if (handler.state case Error()) {
            return Center(
              child: IconButton(
                onPressed: handler.refresh,
                icon: const Icon(Icons.refresh),
              ),
            );
          }

          return _buildRecommendations();
        },
      ),
    );
  }

  Widget _buildRecommendations() {
    return _comics.isEmpty
        ? const Empty(height: 190)
        : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _comics.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _comics[index];
              return InkWell(
                onTap: () => context.push('/details/${item.id}'),
                hoverColor: Colors.transparent,
                child: SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      UiImage(
                        borderRadius: BorderRadius.circular(8),
                        shape: .rectangle,
                        url: item.url,
                        width: 100,
                        height: 135,
                      ),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
