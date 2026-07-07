import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/fake_repository.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('with a current server, home shows the library stats', (
    tester,
  ) async {
    await tester.pumpWidget(scopedApp(FakeRepository()));
    await settleLocalization(tester);

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Álbuns'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Artistas'), findsOneWidget);
    expect(find.text('Músicas'), findsOneWidget);
  });
}
