import 'package:easy_localization/easy_localization.dart';
import 'package:feishin_mobile/core/theme/app_theme_id.dart';
import 'package:feishin_mobile/data/repository_provider.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:feishin_mobile/features/auth/auth_controller.dart';
import 'package:feishin_mobile/features/home/home_screen.dart';
import 'package:feishin_mobile/features/settings/theme_controller.dart';
import 'package:feishin_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/fake_repository.dart';

Widget wrapEasyLocalization(Widget child) => EasyLocalization(
  supportedLocales: supportedLocales,
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),
  useFallbackTranslations: true,
  child: child,
);

/// easy_localization's translation asset load doesn't progress under a bare
/// `pump()`/`pumpAndSettle()` in the test binding's fake-async zone — it
/// needs a real async gap via `runAsync` before the tree un-stalls from
/// `Localizations`' loading placeholder. Call once right after the first
/// `pumpWidget` in a test; subsequent taps/navigation don't need it.
///
/// Each scenario using this lives in its own test *file* on purpose:
/// `EasyLocalizationController` keeps process-static state
/// (`_savedLocale`/`_deviceLocale`), and mounting a second, independent
/// `EasyLocalization` tree later in the *same* test process gets that
/// widget's `Localizations` delegate permanently stuck loading (confirmed
/// empirically — splitting by file sidesteps it since `flutter test` runs
/// each file in its own isolate).
Future<void> settleLocalization(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

class FakeAuthController extends AuthController {
  FakeAuthController(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class FakeThemeController extends ThemeController {
  @override
  AppThemeId? build() => null;
}

final testServer = ServerConfig(
  id: 'srv-1',
  name: 'Casa',
  type: ServerType.navidrome,
  url: 'https://music.example.com',
  userId: 'u1',
  username: 'demo',
);

Widget scopedApp(FakeRepository repository) => wrapEasyLocalization(
  ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        () => FakeAuthController(
          AuthState(currentServerId: 'srv-1', servers: [testServer]),
        ),
      ),
      musicServerRepositoryProvider.overrideWith((ref) async => repository),
      libraryStatsProvider.overrideWith(
        (ref) async => (albums: 10, artists: 5, songs: 100),
      ),
      themeControllerProvider.overrideWith(FakeThemeController.new),
    ],
    child: const FeishinApp(),
  ),
);
