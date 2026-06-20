import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// LEGACY shim. Colors now live in the design-token system ([DornaColors]) and
/// the app [ThemeData] (`ColorScheme` / `TextTheme`). Prefer
/// `Theme.of(context).colorScheme` / `DornaColors` in new and redesigned code —
/// these members map old call sites onto the new palette and are removed as
/// screens migrate off them (redesign Phases 1+).
class AppColors {
  static bool isDarkMode = false;

  static Color primaryColor() => DornaColors.primary;
  static Color ascending() => DornaColors.accentCyan;

  static Color mainBlack = DornaColors.onSurface;
  static Color subtitle = DornaColors.onSurface;

  static Color textMain() => DornaColors.onSurface;
  static Color text1 = DornaColors.onSurface;
  static Color text2 = DornaColors.onSurfaceVariant;
  static Color text3 = DornaColors.onSurfaceVariant;

  static Color greySubtext() => DornaColors.onSurfaceVariant;
  static Color grey1 = DornaColors.onSurfaceVariant;
  static Color grey2 = DornaColors.outline;
  static Color grey3 = DornaColors.outline;
  static Color grey4 = DornaColors.outline;
  static Color neutral = DornaColors.outlineVariant;
  static Color neutral2 = DornaColors.surfaceContainerHigh;
  static Color neutral3 = DornaColors.surfaceContainerLow;
  static Color neutral4 = DornaColors.surfaceContainerLowest;
  static Color lightBlue = DornaColors.accentCyan;
  static Color lightBlue2 = DornaColors.accentCyan;
  static Color infoText = DornaColors.info;
  static Color blueDark = DornaColors.onPrimaryContainer;
  static Color warningText = DornaColors.warning;
  static Color warningText2 = DornaColors.warning;
  static Color errorText = DornaColors.error;
  static Color successText = DornaColors.success;
  static Color green1 = DornaColors.success;
  static Color brand4 = DornaColors.error;
  static Color redDark = DornaColors.onErrorContainer;
  static Color purple = DornaColors.tertiary;
}
