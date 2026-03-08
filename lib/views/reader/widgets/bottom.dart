import 'package:flutter/material.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/with_blur.dart';

const kBottomBarHeight = 105.0;
const kBottomBarBottom = 15.0;

/// 底部工具栏
class ReaderBottom extends StatelessWidget {
  const ReaderBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = context.bottom;

    final isM1 = UiMode.m1(context);

    final showToolbar = context.selector((p) => p.showToolbar);

    if (isM1) {
      return AnimatedPositioned(
        bottom: showToolbar ? 0 : -(bottom + kBottomBarHeight),
        left: 0,
        right: 0,
        height: bottom + kBottomBarHeight,
        duration: const Duration(milliseconds: 250),
        child: WithBlur(
          child: Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottom),
            decoration: BoxDecoration(
              color: context.colorScheme.secondaryContainer.withValues(
                alpha: 0.6,
              ),
            ),
            child: _buildContent(context),
          ),
        ),
      );
    }

    return AnimatedPositioned(
      bottom: showToolbar
          ? kBottomBarBottom
          : -(bottom + kBottomBarBottom + kBottomBarHeight),
      left: 0,
      right: 0,
      height: kBottomBarHeight,
      duration: const Duration(milliseconds: 250),
      child: RepaintBoundary(
        child: Align(
          alignment: Alignment.center,
          child: WithBlur(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 550,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.secondaryContainer.withValues(
                  alpha: 0.6,
                ),
              ),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isPageTurning = context.selector((p) => p.isPageTurning);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isPageTurning
          ? _buildPageTurnContent(context)
          : _buildCommonContent(context),
    );
  }

  Widget _buildCommonContent(BuildContext context) {
    final isFirstChapter = context.selector((p) => p.isFirstChapter);
    final isLastChapter = context.selector((p) => p.isLastChapter);

    final previousAction = isFirstChapter
        ? null
        : () {
            context.reader.goPrevious();
            context.reader.openOrCloseToolbar();
          };

    final nextAction = isLastChapter
        ? null
        : () {
            context.reader.goNext();
            context.reader.openOrCloseToolbar();
          };

    return Column(
      key: const ValueKey('common_toolbar'),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.skip_previous),
              onPressed: previousAction,
            ),
            const Expanded(child: PageSlider()),
            IconButton.filledTonal(
              icon: const Icon(Icons.skip_next),
              onPressed: nextAction,
            ),
          ],
        ),
        Expanded(
          child: Row(
            spacing: 5,
            children: [
              IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                  context.reader.openOrCloseToolbar();
                },
                tooltip: '章节',
                icon: const Icon(Icons.menu_outlined),
              ),
              IconButton(
                onPressed: () {
                  context.reader.startPageTurn();
                  context.reader.openOrCloseToolbar();
                },
                tooltip: '定时翻页',
                icon: const Icon(Icons.timer_outlined),
              ),
              IconButton(
                onPressed: () {
                  context.stateReader.toggleLockMenu();
                  context.reader.openOrCloseToolbar();
                },
                tooltip: '锁定菜单',
                icon: const Icon(Icons.lock_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageTurnContent(BuildContext context) {
    final interval = context.selector((p) => p.interval);
    return Column(
      key: const ValueKey('page_turn_toolbar'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('间隔'),
            Expanded(
              child: Slider(
                value: interval.toDouble(),
                min: 2,
                max: 60,
                divisions: 58,
                onChanged: (v) => context.reader.updateInterval(v.round()),
              ),
            ),
            Text('$interval s'),
          ],
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  context.reader.stopPageTurn();
                  context.reader.openOrCloseToolbar();
                },
                child: const Text('关闭自动翻页'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Slider
class PageSlider extends StatelessWidget {
  const PageSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final value = context.selector((p) => p.pageNo);

    final total = context.selector((p) => p.pageCount);

    if (total <= 1) return const SizedBox.shrink();
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: Slider(
        value: value.toDouble(),
        min: 0,
        max: (total - 1).toDouble(),
        divisions: total - 1,
        label: '${value + 1}',
        onChanged: (value) => context.reader.onSliderChanged(value.round()),
      ),
    );
  }
}
