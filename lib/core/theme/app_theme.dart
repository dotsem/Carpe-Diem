import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF292929);
  static const surface = Color(0xFF333333);
  static const surfaceLight = Color(0xFF3D3D3D);
  static const text = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB0B0B0);
  static const accent = Color(0xFFFF7B00);
  static const accentLight = Color(0xFFFF9F40);
  static const error = Color.fromARGB(255, 238, 70, 101);
  static const success = Color(0xFF4CAF50);
  static const info = Color(0xFF2196F3);

  static const priorityUrgent = Color(0xFF8800FF);
  static const priorityHigh = Color(0xFFE53935);
  static const priorityMedium = Color(0xFFFFA726);
  static const priorityLow = Color(0xFF66BB6A);
  static const priorityNone = Color(0xFF757575);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.text,
        onSecondary: AppColors.text,
        onSurface: AppColors.text,
        onError: AppColors.text,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.surfaceLight;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceLight, thickness: 1),
    );
  }
}
