import 'dart:io';

import 'package:feishin_mobile/core/theme/app_theme_id.dart';
import 'package:feishin_mobile/features/settings/theme_controller.dart';
import 'package:feishin_mobile/features/settings/theme_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('feishin_theme_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(ThemeStore.boxName);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [themeStoreProvider.overrideWithValue(ThemeStore(box))],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to null (follow system) when nothing is persisted', () {
    final container = makeContainer();
    expect(container.read(themeControllerProvider), isNull);
  });

  test('select persists the choice and updates state', () async {
    final container = makeContainer();

    await container
        .read(themeControllerProvider.notifier)
        .select(AppThemeId.nord);

    expect(container.read(themeControllerProvider), AppThemeId.nord);
    expect(ThemeStore(box).getSelectedTheme(), AppThemeId.nord);
  });

  test('select(null) clears back to follow system', () async {
    final container = makeContainer();
    final notifier = container.read(themeControllerProvider.notifier);

    await notifier.select(AppThemeId.dracula);
    await notifier.select(null);

    expect(container.read(themeControllerProvider), isNull);
    expect(ThemeStore(box).getSelectedTheme(), isNull);
  });

  test('a fresh controller reads back a previously persisted choice', () async {
    await ThemeStore(box).setSelectedTheme(AppThemeId.tokyoNight);

    final container = makeContainer();
    expect(container.read(themeControllerProvider), AppThemeId.tokyoNight);
  });
}
