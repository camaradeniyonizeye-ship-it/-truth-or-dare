import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF09060D);
  static const Color surface = Color(0xFF17111D);
  static const Color surfaceRaised = Color(0xFF211727);
  static const Color neonRed = Color(0xFFFF3F62);
  static const Color neonBlue = Color(0xFFB267FF);
  static const Color neonPurple = Color(0xFFB267FF);
  static const Color neonPink = Color(0xFFFF3978);
  static const Color neonGreen = Color(0xFF65E6B4);
  static const Color gold = Color(0xFFFFD477);
  static const Color white = Color(0xFFFFF7FC);
  static const Color muted = Color(0xFFB6A9B9);
  static const Color outline = Color(0xFF49334D);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonPink,
          secondary: AppColors.neonPurple,
          surface: AppColors.surface,
          error: AppColors.neonRed,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
          iconTheme: IconThemeData(color: AppColors.white),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -1),
          headlineLarge: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.15),
          headlineMedium: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: AppColors.white, fontSize: 16, height: 1.4),
          bodyMedium: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
          labelLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        cardTheme: CardTheme(
          color: AppColors.surface.withOpacity(.92),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.outline),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceRaised,
          contentTextStyle: const TextStyle(color: AppColors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        dividerColor: AppColors.outline,
      );
}
