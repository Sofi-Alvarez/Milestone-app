import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hito design tokens — índigo suave + arena + salvia, M3 roles.
/// Source: Documento Visual (skill-4-visual), confirmado por el equipo de diseño.
class HitoColors {
  /// Fondo fijo del splash (no varía con light/dark theme, ver SplashScreen).
  static const splashBackground = Color(0xFF1E2040);
  static const splashForeground = Color(0xFFF2F1F4);

  // Light
  static const primaryLight = Color(0xFF4A4E78);
  static const onPrimaryLight = Color(0xFFF2F1F4);
  static const primaryContainerLight = Color(0xFFE2E2EF);
  static const onPrimaryContainerLight = Color(0xFF1E2040);

  static const secondaryLight = Color(0xFFB08B5A);
  static const onSecondaryLight = Color(0xFF3E2D14);
  static const secondaryContainerLight = Color(0xFFF1E3D0);
  static const onSecondaryContainerLight = Color(0xFF3E2D14);

  static const tertiaryLight = Color(0xFF7C9885);
  static const onTertiaryLight = Color(0xFFFFFFFF);
  static const tertiaryContainerLight = Color(0xFFE5EDE7);
  static const onTertiaryContainerLight = Color(0xFF16332B);

  static const successLight = Color(0xFF3F7A4E);
  static const successContainerLight = Color(0xFFDCF0DF);
  static const warningLight = Color(0xFF9A6B00);
  static const warningContainerLight = Color(0xFFFCEBC4);
  static const errorLight = Color(0xFFB3261E);
  static const errorContainerLight = Color(0xFFF9DEDC);

  static const neutral900Light = Color(0xFF211F26);
  static const neutral700Light = Color(0xFF57545E);
  static const neutral50Light = Color(0xFFF2F1F4);
  static const outlineLight = Color(0xFF79767F);

  // Dark
  static const primaryDark = Color(0xFFC3C4E8);
  static const onPrimaryDark = Color(0xFF2A2C50);
  static const primaryContainerDark = Color(0xFF393C66);
  static const onPrimaryContainerDark = Color(0xFFE0E0F5);

  static const secondaryDark = Color(0xFFE0C190);
  static const onSecondaryDark = Color(0xFF4A3618);
  static const secondaryContainerDark = Color(0xFF5C4423);
  static const onSecondaryContainerDark = Color(0xFFF6E3C5);

  static const tertiaryDark = Color(0xFFA0BBA8);
  static const onTertiaryDark = Color(0xFF1F3327);
  static const tertiaryContainerDark = Color(0xFF324A3A);
  static const onTertiaryContainerDark = Color(0xFFC8DDC9);

  static const successDark = Color(0xFF9FD8A8);
  static const successContainerDark = Color(0xFF2A4A33);
  static const warningDark = Color(0xFFE5B95C);
  static const warningContainerDark = Color(0xFF4A3700);
  static const errorDark = Color(0xFFF2B8B5);
  static const errorContainerDark = Color(0xFF601410);

  static const backgroundDark = Color(0xFF18171C);
  static const surfaceDark = Color(0xFF211F26);
  static const surfaceVariantDark = Color(0xFF2A2830);
  static const onSurfaceDark = Color(0xFFECEAF0);
  static const onSurfaceVariantDark = Color(0xFFB8B5C0);
  static const outlineDark = Color(0xFF5C5965);
}

class HitoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class HitoRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
}

class HitoTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: HitoColors.primaryLight,
      onPrimary: HitoColors.onPrimaryLight,
      primaryContainer: HitoColors.primaryContainerLight,
      onPrimaryContainer: HitoColors.onPrimaryContainerLight,
      secondary: HitoColors.secondaryLight,
      onSecondary: HitoColors.onSecondaryLight,
      secondaryContainer: HitoColors.secondaryContainerLight,
      onSecondaryContainer: HitoColors.onSecondaryContainerLight,
      tertiary: HitoColors.tertiaryLight,
      onTertiary: HitoColors.onTertiaryLight,
      tertiaryContainer: HitoColors.tertiaryContainerLight,
      onTertiaryContainer: HitoColors.onTertiaryContainerLight,
      error: HitoColors.errorLight,
      errorContainer: HitoColors.errorContainerLight,
      surface: Colors.white,
      onSurface: HitoColors.neutral900Light,
      surfaceContainerHighest: HitoColors.neutral50Light,
      onSurfaceVariant: HitoColors.neutral700Light,
      outline: HitoColors.outlineLight,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: HitoColors.primaryDark,
      onPrimary: HitoColors.onPrimaryDark,
      primaryContainer: HitoColors.primaryContainerDark,
      onPrimaryContainer: HitoColors.onPrimaryContainerDark,
      secondary: HitoColors.secondaryDark,
      onSecondary: HitoColors.onSecondaryDark,
      secondaryContainer: HitoColors.secondaryContainerDark,
      onSecondaryContainer: HitoColors.onSecondaryContainerDark,
      tertiary: HitoColors.tertiaryDark,
      onTertiary: HitoColors.onTertiaryDark,
      tertiaryContainer: HitoColors.tertiaryContainerDark,
      onTertiaryContainer: HitoColors.onTertiaryContainerDark,
      error: HitoColors.errorDark,
      errorContainer: HitoColors.errorContainerDark,
      surface: HitoColors.surfaceDark,
      onSurface: HitoColors.onSurfaceDark,
      surfaceContainerHighest: HitoColors.surfaceVariantDark,
      onSurfaceVariant: HitoColors.onSurfaceVariantDark,
      outline: HitoColors.outlineDark,
    );
    return _buildTheme(colorScheme).copyWith(
      scaffoldBackgroundColor: HitoColors.backgroundDark,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.manropeTextTheme().copyWith(
      displayMedium: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerHighest,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HitoRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: HitoSpacing.lg,
            vertical: HitoSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HitoRadius.md),
          ),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: HitoSpacing.lg,
            vertical: HitoSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HitoRadius.sm),
          borderSide: BorderSide(color: colorScheme.secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HitoRadius.sm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HitoSpacing.md,
          vertical: HitoSpacing.sm + HitoSpacing.xs,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: HitoColors.neutral900Light.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HitoRadius.md),
        ),
      ),
    );
  }
}
