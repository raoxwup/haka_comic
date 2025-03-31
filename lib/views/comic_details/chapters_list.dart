import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';

class ChaptersList extends StatefulWidget {
  const ChaptersList({super.key, required this.chapters, required this.id});

  final List<Chapter> chapters;

  final String id;

  @override
  State<ChaptersList> createState() => _ChaptersListState();
}

class _ChaptersListState extends State<ChaptersList> {
  bool expand = false;

  /// 正序章节列表
  List<Chapter> get _chapters => widget.chapters.reversed.toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('目录', style: context.textTheme.titleMedium),
        widget.chapters.isEmpty
            ? _buildCircularProgressIndicator()
            : _buildChapterList(),
      ],
    );
  }

  Widget _buildCircularProgressIndicator() => SizedBox(
    height: 200,
    width: double.infinity,
    child: Center(child: const CircularProgressIndicator()),
  );

  Widget _buildChapterList() {
    final chapters =
        expand ? widget.chapters : widget.chapters.take(40).toList();

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
                onTap:
                    () => context.push(
                      '/reader/${widget.id}/${chapter.id}/0',
                      extra: _chapters,
                    ),
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
        if (widget.chapters.length > 40)
          SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (widget.chapters.length > 40)
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
