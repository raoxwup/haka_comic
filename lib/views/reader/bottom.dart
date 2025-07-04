import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/with_blur.dart';

const kBottomBarHeight = 105.0;

enum ReaderBottomActionType { previous, next }

/// 底部工具栏
class ReaderBottom extends StatelessWidget {
  const ReaderBottom({
    super.key,
    required this.onPageNoChanged,
    required this.showToolbar,
    required this.action,
    required this.total,
    required this.pageNo,
  });

  final ValueChanged<int> onPageNoChanged;

  final bool showToolbar;

  final VoidCallback? Function(ReaderBottomActionType) action;

  /// 总页数
  final int total;

  /// 当前页
  final int pageNo;

  @override
  Widget build(BuildContext context) {
    final bottom = context.bottom;

    final previousAction = action(ReaderBottomActionType.previous);
    final nextAction = action(ReaderBottomActionType.next);

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
            color: context.colorScheme.surface.withValues(alpha: 0.92),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: previousAction,
                  ),
                  Expanded(
                    child: PageSlider(
                      onChanged: onPageNoChanged,
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
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: context.colorScheme.onSurface,
                      ),
                      label: const Text('章节'),
                      icon: const Icon(Icons.menu),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Slider(
      value: value.toDouble(),
      min: 0,
      max: (total - 1).toDouble(),
      divisions: total - 1,
      label: '${value + 1}',
      onChanged: (value) => onChanged(value.toInt()),
    );
  }
}
