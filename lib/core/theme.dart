import 'package:flutter/material.dart';

/// MelodyBox 二次元主题 — 深色星空 + 樱花粉 + 暮光紫
class AppTheme {
  AppTheme._();

  // ---- 主色调 ----
  static const Color sakuraPink = Color(0xFFFFB7C5);
  static const Color twilightPurple = Color(0xFF7C5295);
  static const Color skyBlue = Color(0xFF64B5F6);
  static const Color deepNavy = Color(0xFF0D1B3E);
  static const Color darkPurple = Color(0xFF1A0533);

  // ---- 卡片/毛玻璃 ----
  static const Color glassWhite = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
  static const Color cardBackground = Color(0x1AFFFFFF);

  // ---- 文字 ----
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8CC);
  static const Color textHint = Color(0xFF7A8299);

  // ---- 状态 ----
  static const Color success = Color(0xFF81C784);
  static const Color error = Color(0xFFEF9A9A);
  static const Color favorite = Color(0xFFFF6B8A);

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: sakuraPink,
      scaffoldBackgroundColor: deepNavy,
      colorScheme: const ColorScheme.dark(
        primary: sakuraPink,
        secondary: twilightPurple,
        tertiary: skyBlue,
        surface: cardBackground,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'System',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xCC0D1B3E),
        selectedItemColor: sakuraPink,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 22),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        labelSmall: TextStyle(color: textHint, fontSize: 11),
      ),
    );
  }
}
