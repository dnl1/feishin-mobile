import 'package:flutter/material.dart';

/// Mirrors `BaseAppThemeConfiguration.colors` + `mode` from feishin's
/// `app-theme-types.ts`. Each [AppThemeId] resolves to one of these via
/// `kAppThemeTokens` (`app_theme_tokens_data.dart`), already merged with
/// `defaultTheme.colors` the same way `getAppTheme` does on the web side.
class AppThemeTokens {
  const AppThemeTokens({
    required this.background,
    required this.backgroundAlternate,
    required this.black,
    required this.foreground,
    required this.foregroundMuted,
    required this.primary,
    required this.stateError,
    required this.stateInfo,
    required this.stateSuccess,
    required this.stateWarning,
    required this.surface,
    required this.surfaceForeground,
    required this.white,
    required this.mode,
  });

  final Color background;
  final Color backgroundAlternate;
  final Color black;
  final Color foreground;
  final Color foregroundMuted;
  final Color primary;
  final Color stateError;
  final Color stateInfo;
  final Color stateSuccess;
  final Color stateWarning;
  final Color surface;
  final Color surfaceForeground;
  final Color white;
  final Brightness mode;
}
