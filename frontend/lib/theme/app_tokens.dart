import 'package:flutter/material.dart';

/// Raw Dorna design tokens, extracted from `design_reference/.../dorna/DESIGN.md`
/// (the Material-3 YAML token set — the canonical source; the prose hexes and the
/// `_ds/` ConstraAP system are NOT used).
///
/// Prefer consuming colors/typography through the app `ThemeData`
/// (`Theme.of(context).colorScheme` / `textTheme`). Use these raw tokens directly
/// only for brand bits Material can't express — e.g. the signature blue→cyan
/// gradient and the cyan audio-waveform accent.
class DornaColors {
  DornaColors._();

  // ── Primary / brand ──
  static const Color primary = Color(0xFF0062A3);
  static const Color onPrimary = Color(0xFFF7F9FF);
  static const Color primaryContainer = Color(0xFF6AB2FE);
  static const Color onPrimaryContainer = Color(0xFF003054);
  static const Color primaryDim = Color(0xFF005690);

  // ── Secondary (teal-blue) ──
  static const Color secondary = Color(0xFF00687B);
  static const Color onSecondary = Color(0xFFEFFBFF);
  static const Color secondaryContainer = Color(0xFFADECFF);
  static const Color onSecondaryContainer = Color(0xFF005A6A);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFF006497);
  static const Color onTertiary = Color(0xFFF6F9FF);
  static const Color tertiaryContainer = Color(0xFF31ABF7);
  static const Color onTertiaryContainer = Color(0xFF00283F);

  // ── Error ──
  static const Color error = Color(0xFFA83836);
  static const Color onError = Color(0xFFFFF7F6);
  static const Color errorContainer = Color(0xFFFA746F);
  static const Color onErrorContainer = Color(0xFF6E0A12);

  // ── Surfaces / neutrals ──
  static const Color surface = Color(0xFFF6FAFF);
  static const Color surfaceDim = Color(0xFFC4DDF1);
  static const Color surfaceBright = Color(0xFFF6FAFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEAF5FF);
  static const Color surfaceContainer = Color(0xFFDFF0FF);
  static const Color surfaceContainerHigh = Color(0xFFD6EBFC);
  static const Color surfaceContainerHighest = Color(0xFFCCE6FA);
  static const Color onSurface = Color(0xFF1D3544);
  static const Color onSurfaceVariant = Color(0xFF4A6273);
  static const Color outline = Color(0xFF667E8F);
  static const Color outlineVariant = Color(0xFF9CB5C8);
  static const Color inverseSurface = Color(0xFF050F17);
  static const Color inverseOnSurface = Color(0xFF939EA8);
  static const Color inversePrimary = Color(0xFF6AB2FE);

  // ── Signature accent + gradient (blue → cyan) ──
  static const Color accentCyan = Color(0xFF05C1E2);
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, accentCyan],
  );

  // ── Status (from DESIGN.md notes; not part of the M3 token map) ──
  static const Color success = Color(0xFF17BD62);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF039BE5);
}

/// 4px-based spacing scale (mobile screen margin 20, gutter 16).
class DornaSpacing {
  DornaSpacing._();
  static const double unit = 4;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double gutter = 16;
  static const double screenMargin = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii (cards 16–24; pills/avatars `full`).
class DornaRadii {
  DornaRadii._();
  static const double sm = 4;
  static const double base = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}
