import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF1B8C5A);
  static const primaryDark = Color(0xFF14623F);
  static const primaryLight = Color(0xFFE8F5EE);
  static const secondary = Color(0xFFF5A623);
  static const background = Color(0xFFF4F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF0E2118);
  static const muted = Color(0xFF54675B);
  static const border = Color(0xFFDEEAE3);
  static const danger = Color(0xFFD94B3E);
}

class AppTheme {
  const AppTheme._();

  static const fontFamily = 'PlusJakartaSans';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }
}
