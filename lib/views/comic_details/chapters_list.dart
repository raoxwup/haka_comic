import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';

class ChaptersList extends StatefulWidget {
  const ChaptersList({super.key, required this.comicId});

  final String comicId;

  @override
  State<ChaptersList> createState() => _ChaptersListState();
}

class _ChaptersListState extends State<ChaptersList> {
  final handler = fetchChapters.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch chapters success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch chapters error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    handler.run(widget.comicId);

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
    return handler.isLoading
        ? _buildCircularProgressIndicator()
        : _buildChapterList();
  }

  Widget _buildCircularProgressIndicator() => SizedBox(
    height: 200,
    width: double.infinity,
    child: Center(child: const CircularProgressIndicator()),
  );

  Widget _buildChapterList() {
    final chapters = handler.data ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 4,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          child: Center(
            child: Text(
              chapters[index].title,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
