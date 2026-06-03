import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFF050508);
  static const Color bgCard = Color(0xFF0D0D14);
  static const Color bgGlass = Color(0x1AFFFFFF);
  static const Color bgGlass2 = Color(0x0DFFFFFF);

  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDim = Color(0x3300D4FF);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryDim = Color(0x337C3AED);
  static const Color accent = Color(0xFFFF6B35);

  static const Color positive = Color(0xFF00FF88);
  static const Color positiveDim = Color(0x2200FF88);
  static const Color negative = Color(0xFFFF3366);
  static const Color negativeDim = Color(0x22FF3366);
  static const Color neutral = Color(0xFFFFAA00);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color textTertiary = Color(0x55FFFFFF);
  static const Color border = Color(0x1AFFFFFF);
  static const Color borderBright = Color(0x33FFFFFF);

  // Model colors
  static const Color lstm = Color(0xFF00D4FF);
  static const Color gru = Color(0xFF7C3AED);
  static const Color gan = Color(0xFFFF6B35);
  static const Color custom = Color(0xFFFF3366);
  static const Color ensemble = Color(0xFF00FF88);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.bgCard,
          background: AppColors.bg,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.1,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
          displaySmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        dividerTheme: const DividerThemeData(color: AppColors.border),
      );
}
