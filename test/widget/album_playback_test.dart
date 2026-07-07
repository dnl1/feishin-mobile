import 'package:easy_localization/easy_localization.dart';
import 'package:feishin_mobile/features/player/mini_player.dart';
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

  testWidgets('album detail can start playback and open the full player', (
    tester,
  ) async {
    final repository = FakeRepository(albums: [makeAlbum('al-1')]);

    await tester.pumpWidget(scopedApp(repository));
    await settleLocalization(tester);

    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Álbuns'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Álbum al-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Música s-1'));
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byTooltip('Pausar'), findsOneWidget);

    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('Tocando agora'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fila'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Fila'), findsOneWidget);
    expect(find.text('Música s-1'), findsWidgets);
  });
}
