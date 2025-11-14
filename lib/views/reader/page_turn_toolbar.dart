import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/reader/bottom.dart'
    show kBottomBarBottom, kBottomBarHeight;
import 'package:haka_comic/widgets/with_blur.dart';

class PageTurnToolbar extends StatelessWidget {
  const PageTurnToolbar({
    super.key,
    required this.onIntervalChanged,
    required this.showToolbar,
    required this.interval,
    required this.stopPageTurn,
  });

  final ValueChanged<int> onIntervalChanged;

  final bool showToolbar;

  final int interval;

  final VoidCallback stopPageTurn;

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
            child: _buildContent(),
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
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('间隔'),
            Expanded(
              child: Slider(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 20,
                ),
                value: interval.toDouble(),
                min: 2,
                max: 60,
                divisions: 58,
                onChanged: (v) => onIntervalChanged(v.round()),
              ),
            ),
            Text('$interval s'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: stopPageTurn, child: const Text('关闭自动翻页')),
          ],
        ),
      ],
    );
  }
}
