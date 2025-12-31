import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/database/read_record_helper.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comic_details/collect_action.dart';
import 'package:haka_comic/views/comic_details/liked_action.dart';
import 'package:haka_comic/views/comic_details/types.dart';
import 'package:haka_comic/views/download/background_downloader.dart';

class ComicActionBar extends StatelessWidget {
  const ComicActionBar({
    super.key,
    required this.comicId,
    required this.data,
    required this.readRecord,
    required this.onStartRead,
    required this.chapters,
  });

  final String comicId;
  final Comic data;
  final ComicReadRecord? readRecord;
  final ReadCallback onStartRead;
  final List<Chapter> chapters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 10,
        children: [
          if (UiMode.notM1(context)) ...[
            ActionChip(
              avatar: const Icon(Icons.menu_book),
              shape: const StadiumBorder(),
              label: const Text('从头开始'),
              onPressed: () => onStartRead(),
            ),
            if (readRecord != null)
              ActionChip(
                avatar: const Icon(Icons.bookmark),
                shape: const StadiumBorder(),
                label: const Text('继续阅读'),
                onPressed: () => onStartRead(
                  chapterId: readRecord!.chapterId,
                  pageNo: readRecord!.pageNo,
                ),
              ),
          ],
          LikedAction(isLiked: data.isLiked, id: comicId),
          CollectAction(
            isFavorite: data.isFavourite,
            id: comicId,
          ),
          ActionChip(
            avatar: const Icon(Icons.comment),
            shape: const StadiumBorder(),
            label: Text('${data.commentsCount}'),
            onPressed: data.allowComment
                ? () {
                    context.push('/comments/$comicId');
                  }
                : null,
          ),
          ActionChip(
            avatar: const Icon(Icons.download),
            shape: const StadiumBorder(),
            label: const Text('下载'),
            onPressed: () {
              context.push(
                '/downloader',
                extra: {
                  'chapters': chapters,
                  'downloadComic': DownloadComic(
                    id: comicId,
                    title: data.title,
                    cover: data.thumb.url,
                  ),
                },
              );
            },
          ),
        ],
      ),
    );
  }
}