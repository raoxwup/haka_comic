import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/widgets/with_blur.dart';

const kBottomBarHeight = 105.0;
const kBottomBarBottom = 15.0;

enum ReaderBottomActionType { previous, next }

/// 底部工具栏
class ReaderBottom extends StatelessWidget {
  const ReaderBottom({
    super.key,
    required this.onSliderChanged,
    required this.showToolbar,
    required this.action,
    required this.total,
    required this.pageNo,
    required this.isVerticalMode,
    required this.startPageTurn,
  });

  final ValueChanged<int> onSliderChanged;

  final bool showToolbar;

  final VoidCallback? Function(ReaderBottomActionType) action;

  /// 总页数
  final int total;

  /// 当前页
  final int pageNo;

  final bool isVerticalMode;

  final VoidCallback startPageTurn;

  @override
  Widget build(BuildContext context) {
    final bottom = context.bottom;

    final isM1 = UiMode.m1(context);

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
    final previousAction = action(ReaderBottomActionType.previous);
    final nextAction = action(ReaderBottomActionType.next);

    return Column(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.skip_previous),
              onPressed: previousAction,
            ),
            Expanded(
              child: PageSlider(
                onChanged: onSliderChanged,
                value: pageNo,
                total: total,
              ),
            ),
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
                },
                tooltip: '章节',
                icon: const Icon(Icons.menu_outlined),
              ),
              if (isVerticalMode)
                IconButton(
                  onPressed: () {
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
              IconButton(
                onPressed: startPageTurn,
                tooltip: '定时翻页',
                icon: const Icon(Icons.timer_outlined),
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
  final ValueChanged<int> onChanged;

  final int total;

  final int value;

  const PageSlider({
    super.key,
    required this.onChanged,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
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
        onChanged: (value) => onChanged(value.round()),
      ),
    );
  }
}
