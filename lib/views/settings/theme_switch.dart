import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/providers/theme_provider.dart';
import 'package:haka_comic/utils/extension.dart';

class ThemeSwitch extends ConsumerStatefulWidget {
  const ThemeSwitch({super.key});

  @override
  ConsumerState<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends ConsumerState<ThemeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  double _currentLeft = 0;
  double _targetLeft = 0;

  /// 限制最大宽度为400
  double get boxWidth => context.width > 400
      ? 400 - 16 * 2 - 5 * 2
      : context.width - 16 * 2 - 5 * 2;

  int get newTargetIndex {
    final themeMode = ref.read(themeModeProvider);

    return switch (themeMode) {
      ThemeModeOption.system => 0,
      ThemeModeOption.light => 1,
      ThemeModeOption.dark => 2,
    };
  }

  @override
  void initState() {
    super.initState();
    _springController = AnimationController.unbounded(vsync: this)
      ..addListener(_handleSpringUpdate);
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleSpringUpdate() {
    setState(() => _currentLeft = _springController.value);
  }

  void _startSpringAnimation(double target) {
    final simulation = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 500.0,
        ratio: 0.5,
      ),
      _currentLeft,
      target,
      0.0, // 初始速度
    );
    _springController.animateWith(simulation);
  }

  void _handleTap(ThemeModeOption mode) {
    ref.read(themeModeProvider.notifier).updateThemeMode(mode);
  }

  void _handleThemeChange() {
    final newTargetLeft = boxWidth / 3 * newTargetIndex;
    if ((_targetLeft - newTargetLeft).abs() > 0.1) {
      _targetLeft = newTargetLeft;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSpringAnimation(_targetLeft);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _handleThemeChange();

    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Stack(
        children: [
          Positioned(
            left: _currentLeft,
            top: 0,
            bottom: 0,
            width: boxWidth / 3,
            child: Container(
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: ThemeModeOption.values
                  .map(
                    (x) => Expanded(
                      child: InkWell(
                        onTap: () => _handleTap(x),
                        child: Text(
                          x.title,
                          style: context.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
