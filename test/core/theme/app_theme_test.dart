import 'package:feishin_mobile/core/theme/app_theme.dart';
import 'package:feishin_mobile/core/theme/app_theme_id.dart';
import 'package:feishin_mobile/core/theme/feishin_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps tokens onto ColorScheme roles for a dark theme', () {
    final tokens = tokensFor(AppThemeId.nord);
    final data = buildAppThemeData(AppThemeId.nord);

    expect(data.brightness, Brightness.dark);
    expect(data.colorScheme.primary, tokens.primary);
    expect(data.colorScheme.surface, tokens.surface);
    expect(data.colorScheme.onSurface, tokens.surfaceForeground);
    expect(data.colorScheme.error, tokens.stateError);
    expect(data.scaffoldBackgroundColor, tokens.background);
  });

  test('maps tokens onto ColorScheme roles for a light theme', () {
    final tokens = tokensFor(AppThemeId.defaultLight);
    final data = buildAppThemeData(AppThemeId.defaultLight);

    expect(data.brightness, Brightness.light);
    expect(data.colorScheme.primary, tokens.primary);
    expect(data.colorScheme.surface, tokens.surface);
  });

  test('exposes the extra semantic tokens via FeishinColors', () {
    final tokens = tokensFor(AppThemeId.dracula);
    final data = buildAppThemeData(AppThemeId.dracula);
    final colors = data.extension<FeishinColors>()!;

    expect(colors.background, tokens.background);
    expect(colors.backgroundAlternate, tokens.backgroundAlternate);
    expect(colors.foregroundMuted, tokens.foregroundMuted);
    expect(colors.stateSuccess, tokens.stateSuccess);
    expect(colors.stateWarning, tokens.stateWarning);
  });

  test('builds a valid ThemeData for every ported theme', () {
    for (final id in AppThemeId.values) {
      final data = buildAppThemeData(id);
      expect(data.useMaterial3, isTrue, reason: id.name);
      expect(data.extension<FeishinColors>(), isNotNull, reason: id.name);
    }
  });
}
