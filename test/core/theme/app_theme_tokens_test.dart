import 'package:feishin_mobile/core/theme/app_theme_id.dart';
import 'package:feishin_mobile/core/theme/app_theme_tokens_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all 32 AppThemeId values have tokens', () {
    expect(kAppThemeTokens.length, AppThemeId.values.length);
    for (final id in AppThemeId.values) {
      expect(kAppThemeTokens.containsKey(id), isTrue, reason: id.name);
    }
  });

  // Spot-checked by hand against feishin's src/shared/themes/*/*.ts —
  // catches regressions if the data table is ever hand-edited or
  // regenerated incorrectly.
  test('nord matches its web source colors', () {
    final t = kAppThemeTokens[AppThemeId.nord]!;
    expect(t.mode, Brightness.dark);
    expect(t.background, const Color(0xFF2E3440));
    expect(t.backgroundAlternate, const Color(0xFF252936));
    expect(t.foreground, const Color(0xFFECEFF4));
    expect(t.foregroundMuted, const Color(0xFFD8DEE9));
    expect(t.primary, const Color(0xFF88C0D0));
    expect(t.stateError, const Color(0xFFBF616A));
    expect(t.stateSuccess, const Color(0xFFA3BE8C));
    expect(t.stateWarning, const Color(0xFFEBCB8B));
    expect(t.surface, const Color(0xFF3B4252));
    expect(t.surfaceForeground, const Color(0xFFECEFF4));
  });

  test('highContrastDark matches its web source colors', () {
    final t = kAppThemeTokens[AppThemeId.highContrastDark]!;
    expect(t.mode, Brightness.dark);
    expect(t.background, const Color(0xFF000000));
    expect(t.foreground, const Color(0xFFFFFFFF));
    expect(t.primary, const Color(0xFF00BFFF));
    expect(t.stateError, const Color(0xFFFF0000));
    expect(t.stateSuccess, const Color(0xFF00FF00));
    expect(t.stateWarning, const Color(0xFFFFFF00));
  });

  test('rosePineMoon (hex source colors) matches its web source', () {
    final t = kAppThemeTokens[AppThemeId.rosePineMoon]!;
    expect(t.mode, Brightness.dark);
    expect(t.background, const Color(0xFF232136));
    expect(t.surface, const Color(0xFF191724));
    expect(t.primary, const Color(0xFFEA9A97));
    expect(t.foregroundMuted, const Color(0xFF6E6A86));
  });

  test('defaultDark falls back to defaultTheme.colors except primary', () {
    final t = kAppThemeTokens[AppThemeId.defaultDark]!;
    expect(t.mode, Brightness.dark);
    expect(t.background, const Color(0xFF0C0C0C));
    expect(t.backgroundAlternate, const Color(0xFF080808));
    expect(t.primary, const Color(0xFF3574FC));
    expect(t.surface, const Color(0xFF141414));
  });

  test('defaultLight matches its web source colors', () {
    final t = kAppThemeTokens[AppThemeId.defaultLight]!;
    expect(t.mode, Brightness.light);
    expect(t.background, const Color(0xFFEBEBEB));
    expect(t.foreground, const Color(0xFF191919));
    expect(t.primary, const Color(0xFF007AFF));
    expect(t.surfaceForeground, const Color(0xFF000000));
  });

  test(
    'glassyDark inherits primary from defaultTheme (undefined in source)',
    () {
      final t = kAppThemeTokens[AppThemeId.glassyDark]!;
      expect(t.mode, Brightness.dark);
      expect(t.primary, const Color(0xFF3574FC));
      expect(t.background, const Color(0xFF020203));
      expect(t.surface, const Color(0xFF040405));
    },
  );
}
