import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

/// Semantic tokens from feishin's web themes that don't map onto a
/// Material 3 [ColorScheme] role 1:1 (e.g. `background-alternate`,
/// `state-success`/`state-warning`). Read via
/// `Theme.of(context).extension<FeishinColors>()`.
@immutable
class FeishinColors extends ThemeExtension<FeishinColors> {
  const FeishinColors({
    required this.background,
    required this.backgroundAlternate,
    required this.foregroundMuted,
    required this.stateSuccess,
    required this.stateWarning,
  });

  factory FeishinColors.fromTokens(AppThemeTokens tokens) {
    return FeishinColors(
      background: tokens.background,
      backgroundAlternate: tokens.backgroundAlternate,
      foregroundMuted: tokens.foregroundMuted,
      stateSuccess: tokens.stateSuccess,
      stateWarning: tokens.stateWarning,
    );
  }

  final Color background;
  final Color backgroundAlternate;
  final Color foregroundMuted;
  final Color stateSuccess;
  final Color stateWarning;

  @override
  FeishinColors copyWith({
    Color? background,
    Color? backgroundAlternate,
    Color? foregroundMuted,
    Color? stateSuccess,
    Color? stateWarning,
  }) {
    return FeishinColors(
      background: background ?? this.background,
      backgroundAlternate: backgroundAlternate ?? this.backgroundAlternate,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      stateSuccess: stateSuccess ?? this.stateSuccess,
      stateWarning: stateWarning ?? this.stateWarning,
    );
  }

  @override
  FeishinColors lerp(ThemeExtension<FeishinColors>? other, double t) {
    if (other is! FeishinColors) return this;
    return FeishinColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundAlternate: Color.lerp(
        backgroundAlternate,
        other.backgroundAlternate,
        t,
      )!,
      foregroundMuted: Color.lerp(foregroundMuted, other.foregroundMuted, t)!,
      stateSuccess: Color.lerp(stateSuccess, other.stateSuccess, t)!,
      stateWarning: Color.lerp(stateWarning, other.stateWarning, t)!,
    );
  }
}
