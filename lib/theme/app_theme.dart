import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color neonRed = Color(0xFFFF0000);
  static const Color neonBlue = Color(0xFF0080FF);
  static const Color neonPurple = Color(0xFF8000FF);
  static const Color neonPink = Color(0xFFFF0080);
  static const Color neonGreen = Color(0xFF00FF80);
  static const Color gold = Color(0xFFFFD700);
  static const Color white = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonPink,
          secondary: AppColors.neonBlue,
          surface: AppColors.background,
          error: AppColors.neonRed,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.white, fontSize: 48, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: AppColors.white, fontSize: 18),
        ),
        cardTheme: CardTheme(
          color: Colors.grey[900]?.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.neonPurple, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonPink,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      );
}
