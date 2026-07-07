import 'package:flutter/material.dart';

import 'app_theme_id.dart';
import 'app_theme_tokens.dart';
import 'app_theme_tokens_data.dart';
import 'feishin_colors.dart';

/// Builds a Material 3 [ThemeData] from a feishin [AppThemeId], mapping the
/// web app's ~12 semantic color tokens onto [ColorScheme] roles. Starts from
/// [ColorScheme.dark]/[ColorScheme.light] (for the M3 roles feishin's theme
/// contract has no opinion on) and overrides the roles it does define.
ThemeData buildAppThemeData(AppThemeId id) {
  final tokens = tokensFor(id);
  final base = tokens.mode == Brightness.dark
      ? const ColorScheme.dark()
      : const ColorScheme.light();

  final colorScheme = base.copyWith(
    brightness: tokens.mode,
    primary: tokens.primary,
    onPrimary: _contrastOf(tokens.primary, tokens),
    secondary: tokens.stateInfo,
    onSecondary: _contrastOf(tokens.stateInfo, tokens),
    surface: tokens.surface,
    onSurface: tokens.surfaceForeground,
    surfaceContainerHighest: tokens.backgroundAlternate,
    error: tokens.stateError,
    onError: _contrastOf(tokens.stateError, tokens),
    outline: tokens.foregroundMuted,
    scrim: tokens.black,
  );

  return ThemeData(
    brightness: tokens.mode,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.background,
    useMaterial3: true,
    extensions: [FeishinColors.fromTokens(tokens)],
  );
}

AppThemeTokens tokensFor(AppThemeId id) => kAppThemeTokens[id]!;

/// Picks [AppThemeTokens.black] or [AppThemeTokens.white], whichever
/// contrasts more with [color] — mirrors the browser choosing readable text
/// over an arbitrary background without hand-tuning an `on*` color per theme.
Color _contrastOf(Color color, AppThemeTokens tokens) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? tokens.white
      : tokens.black;
}
