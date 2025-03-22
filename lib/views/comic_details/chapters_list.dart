import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';

class ChaptersList extends StatefulWidget {
  const ChaptersList({super.key, required this.id});

  final String id;

  @override
  State<ChaptersList> createState() => _ChaptersListState();
}

class _ChaptersListState extends State<ChaptersList> {
  bool expand = false;

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
    handler
      ..addListener(_update)
      ..run(widget.id);

    super.initState();
  }

  @override
  void dispose() {
    handler
      ..removeListener(_update)
      ..dispose();
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
    final data = handler.data ?? [];
    final chapters = expand ? data : data.take(40).toList();

    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverGrid.builder(
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
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Center(
                    child: Text(
                      chapters[index].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (data.length > 40) SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (data.length > 40)
          SliverToBoxAdapter(
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    expand = !expand;
                  });
                },
                label: Text(expand ? '收起' : '展开'),
                icon: Icon(expand ? Icons.expand_less : Icons.expand_more),
              ),
            ),
          ),
      ],
    );
  }
}
