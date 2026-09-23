import 'package:flutter/material.dart';

import 'brand_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? BrandColors.deepNavy : BrandColors.offWhite;
    final foreground = isDark
        ? BrandColors.textOnDark
        : BrandColors.textOnLight;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: BrandColors.cyan,
          brightness: brightness,
        ).copyWith(
          primary: BrandColors.cyan,
          onPrimary: BrandColors.contentOnCyan,
          secondary: BrandColors.coral,
          onSecondary: BrandColors.contentOnCoral,
          surface: surface,
          onSurface: foreground,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.cyan,
          foregroundColor: BrandColors.contentOnCyan,
        ),
      ),
      // Material otherwise uses primary (cyan) for text on light surfaces.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: foreground),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: foreground),
      ),
    );
  }
}
