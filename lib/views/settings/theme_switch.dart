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
  late AnimationController _controller;

  double _start = 0;
  double _end = 0;

  static const int itemCount = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _start = _controller.value;
    _end = target;

    const spring = SpringDescription(mass: 1, stiffness: 550, damping: 15);

    final simulation = SpringSimulation(spring, _start, _end, 0);

    _controller.animateWith(simulation);
  }

  void _handleTap(ThemeModeOption mode) {
    ref.read(themeModeProvider.notifier).updateThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    final currentIndex = switch (themeMode) {
      ThemeModeOption.system => 0,
      ThemeModeOption.light => 1,
      ThemeModeOption.dark => 2,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = (totalWidth - 10) / itemCount;

        // 正向计算目标位置
        final targetX = currentIndex * itemWidth;

        // 当状态变化时触发物理动画
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_end != targetX) {
            _animateTo(targetX);
          }
        });

        return Container(
          height: 50,
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  return Positioned(
                    left: _controller.value,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: ThemeModeOption.values.map((x) {
                  return Expanded(
                    child: InkWell(
                      onTap: () => _handleTap(x),
                      child: Center(
                        child: Text(
                          x.title,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
