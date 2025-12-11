import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';

final imagesProvider = FutureProvider.autoDispose
    .family<List<ChapterImage>, FetchChapterImagesPayload>((
      ref,
      payload,
    ) async {
      return fetchChapterImages(payload);
    });
