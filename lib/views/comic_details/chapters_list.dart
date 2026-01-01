import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/comic_details/title_box.dart';
import 'package:haka_comic/views/comic_details/types.dart';

class ChaptersList extends StatefulWidget {
  const ChaptersList({
    super.key,
    required this.chapters,
    required this.startRead,
  });

  final List<Chapter> chapters;

  final ReadCallback startRead;

  @override
  State<ChaptersList> createState() => _ChaptersListState();
}

class _ChaptersListState extends State<ChaptersList> {
  bool expand = false;
  bool isLatestToOldest = true;

  List<Chapter> get sortedChapters =>
      isLatestToOldest ? widget.chapters : widget.chapters.reversed.toList();

  @override
  Widget build(BuildContext context) {
    return TitleBox(
      title: '目录',
      actions: [
        IconButton(
          icon: Icon(
            isLatestToOldest
                ? Icons.vertical_align_top
                : Icons.vertical_align_bottom,
          ),
          onPressed: () {
            setState(() {
              isLatestToOldest = !isLatestToOldest;
            });
          },
        ),
      ],
      builder: (context) {
        if (widget.chapters.isEmpty) {
          return const SizedBox(
            height: 200,
            width: double.infinity,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildChapterList();
      },
    );
  }

  Widget _buildChapterList() {
    final chapters = expand ? sortedChapters : sortedChapters.take(40).toList();

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
            final chapter = chapters[index];
            return Card(
              elevation: 0,
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () => widget.startRead(chapterId: chapter.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Center(
                    child: Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.chapters.length > 40) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
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
      ],
    );
  }
}