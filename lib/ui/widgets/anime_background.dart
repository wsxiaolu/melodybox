import 'dart:math';
import 'package:flutter/material.dart';

/// 二次元星空背景：深色渐变 + 闪烁星星 + 飘落粒子
class AnimeBackground extends StatefulWidget {
  final Widget child;

  const AnimeBackground({super.key, required this.child});

  @override
  State<AnimeBackground> createState() => _AnimeBackgroundState();
}

class _AnimeBackgroundState extends State<AnimeBackground>
    with TickerProviderStateMixin {
  late final AnimationController _starController;
  late final AnimationController _petalController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _petalController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _starController.dispose();
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 底层：深色星空渐变
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B0820), // 深紫夜空顶部
                Color(0xFF141036), // 深蓝过渡
                Color(0xFF1A0A2E), // 暮光紫
                Color(0xFF0D1B3E), // 深蓝底部
              ],
            ),
          ),
        ),

        // 中层：星空 + 粒子动画
        AnimatedBuilder(
          animation: Listenable.merge([_starController, _petalController]),
          builder: (context, _) {
            return CustomPaint(
              size: size,
              painter: _StarrySkyPainter(
                starPhase: _starController.value,
                petalPhase: _petalController.value,
              ),
            );
          },
        ),

        // 顶层：App 内容
        widget.child,
      ],
    );
  }
}

/// 星空+樱花花瓣绘制器
class _StarrySkyPainter extends CustomPainter {
  final double starPhase;
  final double petalPhase;

  _StarrySkyPainter({required this.starPhase, required this.petalPhase});

  @override
  void paint(Canvas canvas, Size size) {
    _drawStars(canvas, size);
    _drawPetals(canvas, size);
  }

  /// 画闪烁的星星
  void _drawStars(Canvas canvas, Size size) {
    final rng = Random(42); // 固定种子保证每次绘制一致
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.8;
      final radius = rng.nextDouble() * 2.0 + 0.5;
      final phase = rng.nextDouble(); // 每颗星的闪烁相位不同

      // 闪烁效果
      final alpha = (0.3 + 0.7 * (0.5 + 0.5 * sin((starPhase + phase) * 2 * pi))).clamp(0.0, 1.0);
      starPaint.color = Colors.white.withAlpha((alpha * 200).round());
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  /// 画飘落的花瓣粒子
  void _drawPetals(Canvas canvas, Size size) {
    final rng = Random(137);
    final petalPaint = Paint()..style = PaintingStyle.fill;

    // 樱花粉色
    const petalColor = Color(0xFFFFB7C5);

    for (int i = 0; i < 20; i++) {
      final startX = rng.nextDouble() * size.width;
      final phase = rng.nextDouble();
      final speed = rng.nextDouble() * 0.3 + 0.1;

      // 飘落动画
      final x = startX + 30 * sin((petalPhase + phase) * 2 * pi / speed);
      final y = ((petalPhase + phase) * size.height * 1.4) % (size.height + 40) - 20;

      final alpha = (0.3 + 0.4 * (0.5 + 0.5 * sin((petalPhase + phase) * 3))).clamp(0.0, 1.0);
      petalPaint.color = petalColor.withAlpha((alpha * 150).round());

      // 画小椭圆作为花瓣
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(petalPhase * 2 * pi * phase);
      canvas.drawOval(
        const Rect.fromLTWH(-3, -1.5, 6, 3),
        petalPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarrySkyPainter oldDelegate) {
    return starPhase != oldDelegate.starPhase || petalPhase != oldDelegate.petalPhase;
  }
}
