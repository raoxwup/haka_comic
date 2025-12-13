import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/with_blur.dart';
import 'package:provider/provider.dart';

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
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
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

    final previousAction = isFirstChapter ? null : context.reader.goPrevious;

    final nextAction = isLastChapter ? null : context.reader.goNext;

    final isVerticalMode = context.selector((p) => p.readMode.isVertical);

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
              if (isVerticalMode)
                IconButton(
                  onPressed: () {
                    context.reader.openOrCloseToolbar();
                    final slipFactor = ValueNotifier(AppConf().slipFactor);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          contentPadding: const EdgeInsets.all(20),
                          title: const Text('滑动距离'),
                          children: [
                            const Text('用于调整阅读时翻页的滑动距离。'),
                            ValueListenableBuilder<double>(
                              valueListenable: slipFactor,
                              builder: (context, value, child) {
                                return Slider(
                                  value: value * 10,
                                  min: 3,
                                  max: 10,
                                  divisions: 7,
                                  label: '$value * 屏高',
                                  onChanged: (double value) {
                                    slipFactor.value = value / 10;
                                    AppConf().slipFactor = value / 10;
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  tooltip: '滑动距离',
                  icon: const Icon(Icons.straighten_outlined),
                ),
              if (isVerticalMode)
                IconButton(
                  onPressed: () {
                    context.reader.openOrCloseToolbar();
                    final stateReader = context.stateReader;
                    showDialog(
                      context: context,
                      builder: (context) {
                        return ChangeNotifierProvider.value(
                          value: stateReader,
                          child: SimpleDialog(
                            contentPadding: const EdgeInsets.all(20),
                            title: const Text('漫画宽度'),
                            children: [
                              const Text('用于调整阅读时漫画的宽度。'),
                              Builder(
                                builder: (c) {
                                  final widthRatio = c.stateSelector(
                                    (p) => p.verticalListWidthRatio,
                                  );
                                  return Slider(
                                    value: widthRatio * 10,
                                    min: 2,
                                    max: 10,
                                    divisions: 8,
                                    label: '$widthRatio * 屏宽',
                                    onChanged: (double v) {
                                      c.stateReader.verticalListWidthRatio =
                                          v / 10;
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  tooltip: '漫画宽度',
                  icon: const Icon(Icons.width_normal_outlined),
                ),
              IconButton(
                onPressed: () {
                  context.reader.startPageTurn();
                  context.reader.openOrCloseToolbar();
                },
                tooltip: '定时翻页',
                icon: const Icon(Icons.timer_outlined),
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
