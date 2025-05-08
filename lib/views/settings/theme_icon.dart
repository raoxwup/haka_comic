import 'package:flutter/material.dart';
import 'dart:math';

const double radius = 70;

class ThemeIcon extends StatefulWidget {
  const ThemeIcon({super.key});

  @override
  State<ThemeIcon> createState() => _ThemeIconState();
}

class _ThemeIconState extends State<ThemeIcon> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> maskAnimation;
  late Animation<double> cyAnimation;
  late Animation<Color?> color1Animation;
  late Animation<Color?> color2Animation;
  Brightness? _currentBrightness;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    maskAnimation = Tween<double>(
      begin: 0,
      end: radius,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    cyAnimation = Tween<double>(
      begin: 0,
      end: radius / 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    color1Animation = ColorTween(
      begin: const Color(0xFFFF4467),
      end: const Color(0xFF8371FF),
    ).animate(_controller);

    color2Animation = ColorTween(
      begin: const Color(0xFFFF8E0B),
      end: const Color(0xFF86BFFF),
    ).animate(_controller);
  }

  void _updateTheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newBrightness = Theme.of(context).brightness;
    if (newBrightness != _currentBrightness) {
      _currentBrightness = newBrightness;
      _updateTheme(newBrightness);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: 45 * pi / 180,
          child: CustomPaint(
            size: const Size(radius * 2, radius * 2),
            painter: IconPainter(
              maskValue: maskAnimation.value,
              cyValue: cyAnimation.value,
              color1: color1Animation.value!,
              color2: color2Animation.value!,
            ),
          ),
        );
      },
    );
  }
}

class IconPainter extends CustomPainter {
  final double maskValue;
  final double cyValue;
  final Color color1;
  final Color color2;

  IconPainter({
    required this.maskValue,
    required this.cyValue,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = const Offset(radius, radius);

    // 绘制渐变背景
    final gradient = LinearGradient(
      colors: [color1, color2],
      transform: const GradientRotation(-90 * pi / 180),
    );

    final backgroundPaint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          );

    // 创建遮罩
    final maskLayer = Paint()..blendMode = BlendMode.dstOut;

    // 绘制主体
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());

    // 绘制背景圆形
    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制遮罩圆形
    canvas.drawCircle(Offset(radius, cyValue), maskValue, maskLayer);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IconPainter oldDelegate) {
    return oldDelegate.maskValue != maskValue ||
        oldDelegate.cyValue != cyValue ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2;
  }
}
