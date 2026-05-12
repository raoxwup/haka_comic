import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/comic_details/recommendation.dart';

void main() {
  test(
    'streams extra recommendations with default limit and ignores failed details',
    () async {
      ExtraRecommendComicPayload? receivedPayload;
      var activeDetails = 0;
      var maxActiveDetails = 0;

      final stream = streamExtraRecommendComics(
        'source-comic-id',
        concurrency: 2,
        fetchIds: (payload) async {
          receivedPayload = payload;
          return const ExtraRecommendComicIdsResponse(
            code: 1,
            recommendations: ['a', 'bad', 'b', 'c'],
            count: 4,
          );
        },
        fetchDetails: (id) async {
          activeDetails++;
          maxActiveDetails = math.max(maxActiveDetails, activeDetails);
          try {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            if (id == 'bad') {
              throw Exception('detail failed');
            }
            return _detailsResponse(id);
          } finally {
            activeDetails--;
          }
        },
      );

      final comics = await stream.toList();

      expect(receivedPayload?.id, 'source-comic-id');
      expect(receivedPayload?.limit, 10);
      expect(maxActiveDetails, lessThanOrEqualTo(2));
      expect(comics.map((comic) => comic.id), unorderedEquals(['a', 'b', 'c']));
      expect(
        comics.map((comic) => comic.title),
        unorderedEquals(['title-a', 'title-b', 'title-c']),
      );
      expect(
        comics.map((comic) => comic.pic),
        everyElement(contains('/static/')),
      );
    },
  );
}

ComicDetailsResponse _detailsResponse(String id) {
  return ComicDetailsResponse(
    comic: Comic(
      id: id,
      title: 'title-$id',
      author: 'author',
      categories: const [],
      chineseTeam: '',
      created_at: '',
      description: '',
      epsCount: 0,
      finished: false,
      isFavourite: false,
      isLiked: false,
      likesCount: 0,
      pagesCount: 0,
      tags: const [],
      thumb: ImageDetail(
        fileServer: 'https://picacomic.example/static',
        path: '/$id.jpg',
        originalName: '$id.jpg',
      ),
      totalLikes: 0,
      totalViews: 0,
      totalComments: 0,
      updated_at: '',
      viewsCount: 0,
      creator: Creator(
        id: 'creator',
        characters: const [],
        exp: 0,
        gender: 'm',
        level: 1,
        name: 'creator',
        role: '',
        title: '',
        avatar: null,
      ),
      allowDownload: true,
      allowComment: true,
      commentsCount: 0,
    ),
  );
}
