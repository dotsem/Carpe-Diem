import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark Theme Colors
  static const backgroundDark = Color(0xFF292929);
  static const surfaceDark = Color(0xFF333333);
  static const surfaceLightDark = Color(0xFF3D3D3D);
  static const textDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFFB0B0B0);

  // Light Theme Colors
  static const backgroundLight = Color(0xFFF5F5F5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightLight = Color(0xFFE0E0E0);
  static const textLight = Color(0xFF1A1A1A);
  static const textSecondaryLight = Color(0xFF616161);

  // Brand Colors
  static const accent = Color(0xFFFF7B00);
  static const accentLight = Color(0xFFFF9F40);
  static const error = Color.fromARGB(255, 238, 70, 101);
  static const success = Color(0xFF4CAF50);
  static const info = Color(0xFF2196F3);
  static const warning = Color.fromARGB(255, 231, 209, 4);

  // Helper getters (backwards compatibility or default)
  static Color get background => backgroundDark;
  static Color get surface => surfaceDark;
  static Color get text => textDark;
  static Color get textSecondary => textSecondaryDark;
}

class AppTheme {
  static ThemeData light(ColorScheme? dynamicColorScheme) {
    final colorScheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
          primary: AppColors.accent,
          surface: AppColors.surfaceLight,
          surfaceContainer: const Color(0xFFF8F8F8),
          surfaceContainerHigh: const Color(0xFFF0F0F0),
          surfaceContainerHighest: const Color(0xFFE8E8E8),
          outline: const Color(0xFFD0D0D0),
          outlineVariant: const Color(0xFFE8E8E8),
          error: AppColors.error,
        );

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.textLight, displayColor: AppColors.textLight);

    return _buildTheme(base, colorScheme, textTheme, Brightness.light);
  }

  static ThemeData dark(ColorScheme? dynamicColorScheme) {
    final colorScheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
          primary: AppColors.accent,
          surface: AppColors.surfaceDark,
          surfaceContainer: const Color(0xFF2C2C2C),
          surfaceContainerHigh: const Color(0xFF333333),
          surfaceContainerHighest: const Color(0xFF3D3D3D),
          outline: const Color(0xFF4A4A4A),
          outlineVariant: const Color(0xFF3D3D3D),
          error: AppColors.error,
        );

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark);

    return _buildTheme(base, colorScheme, textTheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ThemeData base, ColorScheme colorScheme, TextTheme textTheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceLightColor = isDark ? AppColors.surfaceLightDark : AppColors.surfaceLightLight;

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceLightDark : const Color(0xFFFBFBFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(color: surfaceLightColor, thickness: 1, space: 1),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(40, 40),
          iconSize: 24,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(40, 40),
          fixedSize: const Size.fromHeight(40),
          iconSize: 24,
        ),
      ),
    );
  }
}
