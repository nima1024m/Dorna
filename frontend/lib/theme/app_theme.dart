import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Central app theming. Light uses the exact Material-3 scheme from the design
/// tokens; dark is derived from the brand seed (the design ships no dark palette
/// yet — refine later). Typography is Inter (via google_fonts).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _theme(_lightScheme);
  static ThemeData get dark => _theme(_darkScheme);

  /// Exact Material-3 light scheme from DESIGN.md.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: DornaColors.primary,
    onPrimary: DornaColors.onPrimary,
    primaryContainer: DornaColors.primaryContainer,
    onPrimaryContainer: DornaColors.onPrimaryContainer,
    secondary: DornaColors.secondary,
    onSecondary: DornaColors.onSecondary,
    secondaryContainer: DornaColors.secondaryContainer,
    onSecondaryContainer: DornaColors.onSecondaryContainer,
    tertiary: DornaColors.tertiary,
    onTertiary: DornaColors.onTertiary,
    tertiaryContainer: DornaColors.tertiaryContainer,
    onTertiaryContainer: DornaColors.onTertiaryContainer,
    error: DornaColors.error,
    onError: DornaColors.onError,
    errorContainer: DornaColors.errorContainer,
    onErrorContainer: DornaColors.onErrorContainer,
    surface: DornaColors.surface,
    onSurface: DornaColors.onSurface,
    onSurfaceVariant: DornaColors.onSurfaceVariant,
    outline: DornaColors.outline,
    outlineVariant: DornaColors.outlineVariant,
    inverseSurface: DornaColors.inverseSurface,
    onInverseSurface: DornaColors.inverseOnSurface,
    inversePrimary: DornaColors.inversePrimary,
    surfaceTint: DornaColors.primary,
    surfaceDim: DornaColors.surfaceDim,
    surfaceBright: DornaColors.surfaceBright,
    surfaceContainerLowest: DornaColors.surfaceContainerLowest,
    surfaceContainerLow: DornaColors.surfaceContainerLow,
    surfaceContainer: DornaColors.surfaceContainer,
    surfaceContainerHigh: DornaColors.surfaceContainerHigh,
    surfaceContainerHighest: DornaColors.surfaceContainerHighest,
  );

  /// Dark scheme derived from the brand seed (D3: design ships no dark values).
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: DornaColors.primary,
    brightness: Brightness.dark,
  );

  static ThemeData _theme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, scheme.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 28),
    );
  }

  /// Inter type scale from DESIGN.md (sizes/weights/line-heights).
  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    return GoogleFonts.interTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.inter(
          fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.inter(
          fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(
          fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, height: 28 / 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, height: 24 / 14, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
    ).apply(bodyColor: onSurface, displayColor: onSurface);
  }
}
