import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/read_mode_provider.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final listControllersProvider = Provider.autoDispose<ListControllersState>(
  (ref) => ListControllersState(ref),
);

class ListControllersState {
  final Ref ref;
  ListControllersState(this.ref);

  final itemScrollController = ItemScrollController();
  final scrollOffsetController = ScrollOffsetController();
  final pageController = PageController();

  /// 底部工具栏Slider OnChanged
  void onSliderChanged(int index) {
    if (ref.watch(readModeProvider).isVertical) {
      itemScrollController.jumpTo(index: index);
    } else {
      pageController.jumpToPage(index);
    }
  }

  /// VerticalList 跳转 offset
  void pageTurnForVertical(double offset) {
    final readerState = ref.watch(comicReaderStateProvider(routerPayloadCache));
    final readerStateNotifier = ref.read(
      comicReaderStateProvider(routerPayloadCache).notifier,
    );
    if (readerState.pageNo == 0 && offset < 0) {
      if (!readerState.isFirstChapter) {
        readerStateNotifier.goPrevious();
      } else {
        Toast.show(message: '没有上一章了');
      }
      return;
    }

    if (readerState.pageNo == readerState.images.length - 1 && offset > 0) {
      if (!readerState.isLastChapter) {
        readerStateNotifier.goNext();
      } else {
        // stopPageTurn();
        Toast.show(message: '没有下一章了');
      }
      return;
    }

    scrollOffsetController.animateScroll(
      offset: offset,
      duration: const Duration(milliseconds: 200),
    );
  }

  void pageTurnForHorizontal([bool isTurnNext = true]) {
    final readerState = ref.watch(comicReaderStateProvider(routerPayloadCache));
    final readerStateNotifier = ref.read(
      comicReaderStateProvider(routerPayloadCache).notifier,
    );
    void previousPage() {
      if (readerState.pageNo == 0) {
        if (!readerState.isFirstChapter) {
          readerStateNotifier.goPrevious();
        } else {
          Toast.show(message: '没有上一章了');
        }
        return;
      }

      pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }

    void nextPage() {
      if (readerState.correctPageNo == readerState.correctPageCount - 1) {
        if (!readerState.isLastChapter) {
          readerStateNotifier.goNext();
        } else {
          // stopPageTurn();
          Toast.show(message: '没有下一章了');
        }
        return;
      }

      pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    }

    isTurnNext ? nextPage() : previousPage();
  }

  /// 向前翻页
  void prev(BuildContext context) {
    if (ref.watch(readModeProvider).isVertical) {
      pageTurnForVertical(context.height * AppConf().slipFactor * -1);
    } else {
      pageTurnForHorizontal(false);
    }
  }

  /// 向后翻页
  void next(BuildContext context) {
    if (ref.watch(readModeProvider).isVertical) {
      pageTurnForVertical(context.height * AppConf().slipFactor);
    } else {
      pageTurnForHorizontal();
    }
  }
}
