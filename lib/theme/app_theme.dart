import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF090711);
  static const Color surface = Color(0xFF171421);
  static const Color surfaceRaised = Color(0xFF211B2C);
  static const Color neonRed = Color(0xFFFF5B6E);
  static const Color neonBlue = Color(0xFF7AA8FF);
  static const Color neonPurple = Color(0xFF9B7BFF);
  static const Color neonPink = Color(0xFFFF4F9A);
  static const Color neonGreen = Color(0xFF55D6A3);
  static const Color gold = Color(0xFFFFD477);
  static const Color white = Color(0xFFF8F5FC);
  static const Color muted = Color(0xFFA9A3B5);
  static const Color outline = Color(0xFF393244);
}

class AppTheme {
  static ThemeData get theme {
    final scheme = const ColorScheme.dark(
      primary: AppColors.neonPink,
      secondary: AppColors.neonBlue,
      surface: AppColors.surface,
      error: AppColors.neonRed,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -1.5),
        headlineLarge: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.15),
        headlineMedium: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: AppColors.white, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface.withOpacity(.92),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.outline)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        hintStyle: const TextStyle(color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.neonPink, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: .6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: const TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: AppColors.outline,
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor: AppColors.neonPink.withOpacity(.2),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(color: AppColors.white),
      ),
    );
  }
}
