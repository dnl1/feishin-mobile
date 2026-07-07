import 'package:feishin_mobile/data/repository_provider.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:feishin_mobile/features/auth/auth_controller.dart';
import 'package:feishin_mobile/features/home/home_screen.dart';
import 'package:feishin_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/fake_repository.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

final _server = ServerConfig(
  id: 'srv-1',
  name: 'Casa',
  type: ServerType.navidrome,
  url: 'https://music.example.com',
  userId: 'u1',
  username: 'demo',
);

ProviderScope _scopedApp(FakeRepository repository) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(
      () => _FakeAuthController(
        AuthState(currentServerId: 'srv-1', servers: [_server]),
      ),
    ),
    musicServerRepositoryProvider.overrideWith((ref) async => repository),
    libraryStatsProvider.overrideWith(
      (ref) async => (albums: 10, artists: 5, songs: 100),
    ),
  ],
  child: const FeishinApp(),
);

void main() {
  testWidgets('without servers, redirects to the servers screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(
              const AuthState(currentServerId: null, servers: []),
            ),
          ),
        ],
        child: const FeishinApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servidores'), findsOneWidget);
    expect(find.textContaining('Nenhum servidor configurado'), findsOneWidget);
  });

  testWidgets('with a current server, home shows the library stats', (
    tester,
  ) async {
    await tester.pumpWidget(_scopedApp(FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Álbuns'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Artistas'), findsOneWidget);
    expect(find.text('Músicas'), findsOneWidget);
  });

  testWidgets('library tab: albums grid paginates and opens the album detail', (
    tester,
  ) async {
    final repository = FakeRepository(
      albums: List.generate(90, (i) => makeAlbum('al-$i')),
    );

    await tester.pumpWidget(_scopedApp(repository));
    await tester.pumpAndSettle();

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
