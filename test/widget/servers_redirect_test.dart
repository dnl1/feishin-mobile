import 'package:easy_localization/easy_localization.dart';
import 'package:feishin_mobile/features/auth/auth_controller.dart';
import 'package:feishin_mobile/features/settings/theme_controller.dart';
import 'package:feishin_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('without servers, redirects to the servers screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapEasyLocalization(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => FakeAuthController(
                const AuthState(currentServerId: null, servers: []),
              ),
            ),
            themeControllerProvider.overrideWith(FakeThemeController.new),
          ],
          child: const FeishinApp(),
        ),
      ),
    );
    await settleLocalization(tester);

    expect(find.text('Servidores'), findsOneWidget);
    expect(find.textContaining('Nenhum servidor configurado'), findsOneWidget);
  });
}
