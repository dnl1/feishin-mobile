import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/fake_repository.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('library tab: albums grid paginates and opens the album detail', (
    tester,
  ) async {
    final repository = FakeRepository(
      albums: List.generate(90, (i) => makeAlbum('al-$i')),
    );

    await tester.pumpWidget(scopedApp(repository));
    await settleLocalization(tester);

    // Home → Biblioteca tab → Álbuns.
    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Álbuns'));
    await tester.pumpAndSettle();

    expect(find.text('Álbum al-0'), findsOneWidget);

    // Infinite scroll: an item from the second page (index >= 60) only
    // exists after loadMore fired and resolved.
    await tester.scrollUntilVisible(
      find.text('Álbum al-75'),
      600,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 100,
    );
    await tester.pumpAndSettle();
    expect(repository.albumListCalls, greaterThanOrEqualTo(2));

    // Open the detail of the now-visible album.
    await tester.tap(find.text('Álbum al-75'));
    await tester.pumpAndSettle();

    expect(find.text('Música s-1'), findsOneWidget);
    expect(find.text('Música s-2'), findsOneWidget);
  });
}
