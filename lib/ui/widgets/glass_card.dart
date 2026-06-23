import 'dart:ui';
import 'package:flutter/material.dart';

/// 毛玻璃效果卡片
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.onTap,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(51),  // 0.2
                Colors.white.withAlpha(13),  // 0.05
              ],
            ),
            border: Border.all(
              color: Colors.white.withAlpha(77), // 0.3
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: card,
        ),
      );
    }

    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: card,
    );
  }
}
