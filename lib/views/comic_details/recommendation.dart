import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';

class Recommendation extends StatefulWidget {
  const Recommendation({super.key, required this.id});

  final String id;

  @override
  State<Recommendation> createState() => _RecommendationState();
}

class _RecommendationState extends State<Recommendation> {
  final List<ExtraRecommendComic> _comics = [];

  late final AsyncRequestHandler1<RecommendComics, String> handler;
  late final AsyncRequestHandler1<List<ExtraRecommendComic>, String>
  extraHandler;

  void _update() => setState(() {});

  @override
  void initState() {
    handler = fetchComicRecommendation.useRequest(
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

    extraHandler = fetchExtraRecommendComics.useRequest(
      onSuccess: (data, _) {
        Log.info('Fetch extra recommendation success', data.toString());
        _comics.addAll(data);
      },
      onError: (e, _) {
        Log.error('Fetch extra recommendation error', e);
      },
    );

    handler
      ..addListener(_update)
      ..run(widget.id);

    extraHandler
      ..addListener(_update)
      ..run(widget.id);

    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();

    extraHandler
      ..removeListener(_update)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (handler.isLoading || handler.error != null)
        ? _buildCircularProgressIndicator()
        : _buildRecommendations();
  }

  Widget _buildCircularProgressIndicator() => SizedBox(
    height: 180,
    width: double.infinity,
    child: Center(
      child:
          handler.error != null
              ? IconButton(
                onPressed: handler.refresh,
                icon: const Icon(Icons.refresh),
              )
              : const CircularProgressIndicator(),
    ),
  );

  Widget _buildRecommendations() {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child:
          _comics.isEmpty
              ? Column(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/icon_empty.png', height: 160),
                  const Text('暂无推荐'),
                ],
              )
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
                          BaseImage(url: item.pic, width: 100, height: 130),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
