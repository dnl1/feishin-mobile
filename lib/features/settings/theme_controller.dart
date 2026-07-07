import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme_id.dart';
import 'theme_store.dart';

final themeStoreProvider = Provider<ThemeStore>(
  (ref) => throw UnimplementedError('themeStoreProvider must be overridden'),
);

final themeControllerProvider = NotifierProvider<ThemeController, AppThemeId?>(
  ThemeController.new,
);

/// The selected [AppThemeId], or `null` to follow the system light/dark
/// scheme with feishin's own default themes.
class ThemeController extends Notifier<AppThemeId?> {
  @override
  AppThemeId? build() => ref.watch(themeStoreProvider).getSelectedTheme();

  Future<void> select(AppThemeId? id) async {
    await ref.read(themeStoreProvider).setSelectedTheme(id);
    state = id;
  }
}
