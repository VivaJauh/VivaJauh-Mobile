import 'package:flutter/material.dart';

import '../models/record_enums.dart';
import 'app_icons.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF1B8C5A);
  static const primaryDark = Color(0xFF14623F);
  static const primaryLight = Color(0xFFE8F5EE);
  static const secondary = Color(0xFFF5A623);
  static const secondaryLight = Color(0xFFFFF3DC);
  static const background = Color(0xFFF4F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF0E2118);
  static const muted = Color(0xFF54675B);
  static const border = Color(0xFFDEEAE3);
  static const danger = Color(0xFFD94B3E);
  static const dangerDark = Color(0xFFA93226);
  static const warning = Color(0xFFF5A623);
  static const warningDark = Color(0xFF8A5A00);
  static const success = Color(0xFF27AE60);
  static const successDark = Color(0xFF1B7A43);
  static const cream = Color(0xFFFFF8EC);
}

class AppRecordStyle {
  const AppRecordStyle._();

  static Color color(RecordType type) => AppColors.primary;
  static Color darkColor(RecordType type) => AppColors.primaryDark;

  static IconData icon(RecordType type) => switch (type) {
    RecordType.feedTransaction => AppIcons.feed,
    RecordType.livestockEvent => AppIcons.livestock,
    RecordType.savingsTransaction => AppIcons.savings,
    RecordType.loanRepayment => AppIcons.loan,
    RecordType.loanApplication => AppIcons.loanApplication,
    RecordType.dailyReport => AppIcons.dailyReport,
    RecordType.sellerCredit => AppIcons.sellerCredit,
    RecordType.correction => AppIcons.correction,
  };
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
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.muted),
        helperStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.text,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryLight;
            }
            return AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryDark;
            }
            return AppColors.muted;
          }),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: fontFamily,
            );
          }
          return const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark);
          }
          return const IconThemeData(color: AppColors.muted);
        }),
      ),
    );
  }
}
