import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:provider/provider.dart';

class ReaderNextChapter extends StatelessWidget {
  const ReaderNextChapter({super.key});

  static bool _shouldShow(ReaderProvider provider) {
    final state = provider.handler.state;
    final images = provider.images;
    final pageNo = provider.pageNo;
    final total = provider.pageCount;

    return !provider.isLastChapter &&
        !state.loading &&
        images.isNotEmpty &&
        pageNo >= total - 2;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ReaderProvider, bool>(
      selector: (_, provider) => _shouldShow(provider),
      builder: (context, isShow, _) {
        return Positioned(
          right: context.right + 16,
          bottom: context.bottom + 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isShow ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isShow ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isShow,
                child: FloatingActionButton(
                  onPressed: context.reader.goNext,
                  child: const Icon(Icons.skip_next),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
