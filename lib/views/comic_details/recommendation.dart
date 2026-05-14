import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/empty.dart';
import 'package:haka_comic/widgets/ui_image.dart';
import 'package:pool/pool.dart';

const _extraRecommendComicLimit = 10;
const _extraRecommendComicConcurrency = 3;

typedef ExtraRecommendComicIdsFetcher =
    Future<ExtraRecommendComicIdsResponse> Function(
      ExtraRecommendComicPayload payload,
    );
typedef ComicDetailsFetcher = Future<ComicDetailsResponse> Function(String id);

Stream<ExtraRecommendComic> streamExtraRecommendComics(
  String id, {
  int limit = _extraRecommendComicLimit,
  int concurrency = _extraRecommendComicConcurrency,
  ExtraRecommendComicIdsFetcher fetchIds = fetchExtraRecommendComicIds,
  ComicDetailsFetcher fetchDetails = fetchComicDetails,
}) {
  var isCancelled = false;
  late final StreamController<ExtraRecommendComic> controller;

  controller = StreamController<ExtraRecommendComic>(
    onListen: () {
      () async {
        final safeConcurrency = concurrency < 1 ? 1 : concurrency;
        final pool = Pool(safeConcurrency);
        try {
          final response = await fetchIds(
            ExtraRecommendComicPayload(id: id, limit: limit),
          );
          final tasks = response.recommendations.map((comicId) {
            return pool.withResource(() async {
              try {
                final details = await fetchDetails(comicId);
                final comic = details.comic;
                if (isCancelled || controller.isClosed) return;
                controller.add(
                  ExtraRecommendComic(
                    id: comic.id,
                    title: comic.title,
                    pic: comic.thumb.url,
                  ),
                );
              } catch (_) {
                // Ignore a failed detail request so the rest can keep loading.
              }
            });
          }).toList();
          await Future.wait(tasks);
        } catch (_) {
          // Ignore extra recommendation failures; official recommendations still render.
        } finally {
          await pool.close();
          if (!controller.isClosed) {
            await controller.close();
          }
        }
      }();
    },
    onCancel: () {
      isCancelled = true;
    },
  );

  return controller.stream;
}

class Recommendation extends StatefulWidget {
  const Recommendation({super.key, required this.id});

  final String id;

  @override
  State<Recommendation> createState() => _RecommendationState();
}

class _RecommendationState extends State<Recommendation> with RequestMixin {
  final List<ExtraRecommendComic> _comics = [];
  StreamSubscription<ExtraRecommendComic>? _extraRecommendationSubscription;

  late final handler = fetchComicRecommendation.useRequest(
    defaultParams: widget.id,
    onSuccess: (data, _) {
      Log.i('Fetch recommendation success', data.toString());
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
      Log.e('Fetch recommendation error', error: e);
    },
  );

  @override
  void initState() {
    super.initState();
    _loadExtraRecommendations();
  }

  @override
  void dispose() {
    _extraRecommendationSubscription?.cancel();
    super.dispose();
  }

  @override
  List<RequestHandler> registerHandler() => [handler];

  void _loadExtraRecommendations() {
    _extraRecommendationSubscription?.cancel();
    _extraRecommendationSubscription = streamExtraRecommendComics(widget.id)
        .listen((comic) {
          if (!mounted) return;
          Log.i('Fetch extra recommendation success', comic.toString());
          setState(() {
            _comics.add(comic);
          });
        });
  }

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
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
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
