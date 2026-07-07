import 'package:hive/hive.dart';

import '../../core/theme/app_theme_id.dart';

/// Persists the user's theme pick (non-secret, mirrors [ServerStore]'s
/// box-per-feature convention). `null` means "follow system" — light/dark
/// resolve to [AppThemeId.defaultLight]/[AppThemeId.defaultDark].
class ThemeStore {
  const ThemeStore(this._box);

  static const String boxName = 'theme_settings';
  static const String _selectedThemeKey = 'selectedTheme';

  final Box<String> _box;

  AppThemeId? getSelectedTheme() {
    final raw = _box.get(_selectedThemeKey);
    if (raw == null) return null;
    return AppThemeId.values.where((id) => id.name == raw).firstOrNull;
  }

  Future<void> setSelectedTheme(AppThemeId? id) => id == null
      ? _box.delete(_selectedThemeKey)
      : _box.put(_selectedThemeKey, id.name);
}
