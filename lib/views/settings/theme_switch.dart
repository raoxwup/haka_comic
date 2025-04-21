import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:haka_comic/model/app_data.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:provider/provider.dart';

class ThemeSwitch extends StatefulWidget {
  const ThemeSwitch({super.key});

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  double _currentLeft = 0;
  double _targetLeft = 0;

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

  void _handleTap(ThemeMode mode) {
    context.read<AppData>().setThemeMode(mode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleThemeChange();
  }

  void _handleThemeChange() {
    final width = context.width - 16 * 2 - 5 * 2;
    // ThemeMode themeMode = context.select<AppData, ThemeMode>(
    //   (data) => data.themeMode,
    // );

    final themeMode = context.watch<AppData>().themeMode;
    int index = switch (themeMode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };

    final newTarget = width / 3 * index;

    if ((_targetLeft - newTarget).abs() > 0.1) {
      _targetLeft = newTarget;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSpringAnimation(_targetLeft);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width - 16 * 2 - 5 * 2;
    return Container(
      width: double.infinity,
      height: 50,
      padding: EdgeInsets.all(5.0),
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
            width: width / 3,
            child: Container(
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _handleTap(ThemeMode.system),
                    child: Text(
                      'System',
                      style: context.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _handleTap(ThemeMode.light),
                    child: Text(
                      'Light',
                      style: context.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _handleTap(ThemeMode.dark),
                    child: Text(
                      'Dark',
                      style: context.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
