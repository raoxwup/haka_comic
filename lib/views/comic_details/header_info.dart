import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/comic_details/icon_text.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class ComicHeaderInfo extends StatelessWidget {
  const ComicHeaderInfo({super.key, required this.data});

  final Comic data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        UiImage(
          borderRadius: BorderRadius.circular(12.0),
          shape: BoxShape.rectangle,
          url: data.thumb.url,
          cacheKey: data.thumb.cacheKey,
          height: 170,
          width: 115,
          cacheWidth: 115,
          filterQuality: FilterQuality.medium,
        ),
        Expanded(
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectionArea(
                child: Text(
                  data.title,
                  style: context.textTheme.titleMedium,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.author?.isNotEmpty == true)
                _InfoRow(
                  onTap: () => context.push('/comics?a=${data.author}'),
                  data: data.author,
                  icon: Icons.person,
                ),
              if (data.chineseTeam.isNotEmpty == true)
                _InfoRow(
                  onTap: () => context.push('/comics?ct=${data.chineseTeam}'),
                  data: data.chineseTeam,
                  icon: Icons.translate,
                ),
              Row(
                spacing: 10,
                children: [
                  IconText(
                    icon: const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    text: formatNumber(data.totalLikes),
                  ),
                  IconText(
                    icon: const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.amber,
                    ),
                    text: formatNumber(data.totalViews),
                  ),
                  IconText(
                    icon: const Icon(
                      Icons.image,
                      size: 16,
                      color: Colors.green,
                    ),
                    text: formatNumber(data.pagesCount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatefulWidget {
  const _InfoRow({required this.data, this.onTap, required this.icon});

  final String? data;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  late final TapGestureRecognizer _tapRecognizer;

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer()..onTap = widget.onTap;
  }

  @override
  void didUpdateWidget(covariant _InfoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tapRecognizer.onTap = widget.onTap;
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _copyData() async {
    await Clipboard.setData(ClipboardData(text: widget.data ?? ''));
    Toast.show(message: '已复制');
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                widget.icon,
                size: 15,
                color: context.colorScheme.primary,
              ),
            ),
          ),
          TextSpan(text: widget.data ?? '', recognizer: _tapRecognizer),
          const WidgetSpan(child: SizedBox(width: 6)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _copyData,
              child: Icon(
                Icons.copy_rounded,
                size: 14,
                color: context.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      style: TextStyle(color: context.colorScheme.primary, fontSize: 13),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
