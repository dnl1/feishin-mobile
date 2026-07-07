import 'package:feishin_mobile/domain/domain.dart';
import 'package:feishin_mobile/features/auth/auth_controller.dart';
import 'package:feishin_mobile/features/home/home_screen.dart';
import 'package:feishin_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(
              AuthState(currentServerId: 'srv-1', servers: [_server]),
            ),
          ),
          libraryStatsProvider.overrideWith(
            (ref) async => (albums: 10, artists: 5, songs: 100),
          ),
        ],
        child: const FeishinApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('10 álbuns · 5 artistas · 100 músicas'), findsOneWidget);
  });
}
