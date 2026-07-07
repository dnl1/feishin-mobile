import 'dart:io';

import 'package:feishin_mobile/data/music_server_repository.dart';
import 'package:feishin_mobile/features/auth/auth_controller.dart';
import 'package:feishin_mobile/features/auth/secure_store.dart';
import 'package:feishin_mobile/features/auth/server_store.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class InMemorySecureStore implements SecureStore {
  final Map<String, String> data = {};

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

void main() {
  late Directory tempDir;
  late Box<String> box;
  late InMemorySecureStore secureStore;
  var authCalls = 0;

  Future<(ServerAuthResult, ServerInfo?)> fakeAuthenticate({
    required String url,
    required String username,
    required String password,
  }) async {
    authCalls++;
    if (password == 'wrong') {
      throw Exception('bad credentials');
    }

    return (
      ServerAuthResult(
        credentials: ServerCredentials(
          credential: 'u=$username&s=salt&t=tok$authCalls',
          ndCredential: 'nd-$authCalls',
        ),
        isAdmin: true,
        userId: 'user-1',
        username: username,
      ),
      ServerInfo(
        features: {
          'bfr': [1],
        },
        version: '0.55.0',
      ),
    );
  }

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        serverStoreProvider.overrideWithValue(ServerStore(box)),
        secureStoreProvider.overrideWithValue(secureStore),
        navidromeAuthenticateProvider.overrideWithValue(fakeAuthenticate),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('feishin_auth_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(ServerStore.boxName);
    secureStore = InMemorySecureStore();
    authCalls = 0;
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('addServer persists config, credentials and current selection',
      () async {
    final container = buildContainer();
    final controller = container.read(authControllerProvider.notifier);
    await container.read(authControllerProvider.future);

    final config = await controller.addServer(
      name: 'Home',
      url: 'https://music.example.com/',
      username: 'demo',
      password: 'pw',
      savePassword: true,
    );

    expect(config.url, 'https://music.example.com'); // trailing slash removed
    expect(config.version, '0.55.0');
    expect(config.features?['bfr'], [1]);
    expect(config.isAdmin, isTrue);

    final state = await container.read(authControllerProvider.future);
    expect(state.servers.map((s) => s.id), [config.id]);
    expect(state.currentServerId, config.id);
    expect(state.currentServer?.name, 'Home');

    expect(secureStore.data['credentials:${config.id}'], contains('nd-1'));
    expect(secureStore.data['password:${config.id}'], 'pw');
  });

  test('addServer without savePassword keeps the password out of storage',
      () async {
    final container = buildContainer();
    final controller = container.read(authControllerProvider.notifier);
    await container.read(authControllerProvider.future);

    final config = await controller.addServer(
      name: 'Home',
      url: 'https://music.example.com',
      username: 'demo',
      password: 'pw',
    );

    expect(secureStore.data.containsKey('password:${config.id}'), isFalse);
  });

  test('deleteServer removes credentials and clears current', () async {
    final container = buildContainer();
    final controller = container.read(authControllerProvider.notifier);
    await container.read(authControllerProvider.future);

    final config = await controller.addServer(
      name: 'Home',
      url: 'https://music.example.com',
      username: 'demo',
      password: 'pw',
      savePassword: true,
    );

    await controller.deleteServer(config.id);

    final state = await container.read(authControllerProvider.future);
    expect(state.servers, isEmpty);
    expect(state.currentServerId, isNull);
    expect(secureStore.data, isEmpty);
  });

  test('reauthenticate re-logs with the stored password', () async {
    final container = buildContainer();
    final controller = container.read(authControllerProvider.notifier);
    await container.read(authControllerProvider.future);

    final config = await controller.addServer(
      name: 'Home',
      url: 'https://music.example.com',
      username: 'demo',
      password: 'pw',
      savePassword: true,
    );

    final fresh = await controller.reauthenticate(config.id);

    expect(fresh?.ndCredential, 'nd-2');
    expect(secureStore.data['credentials:${config.id}'], contains('nd-2'));
  });

  test('reauthenticate returns null without a saved password', () async {
    final container = buildContainer();
    final controller = container.read(authControllerProvider.notifier);
    await container.read(authControllerProvider.future);

    final config = await controller.addServer(
      name: 'Home',
      url: 'https://music.example.com',
      username: 'demo',
      password: 'pw',
    );

    expect(await controller.reauthenticate(config.id), isNull);
    expect(authCalls, 1); // only the original login
  });

  test('persisted servers survive a fresh container (app restart)', () async {
    final first = buildContainer();
    await first.read(authControllerProvider.future);
    final config = await first
        .read(authControllerProvider.notifier)
        .addServer(
          name: 'Home',
          url: 'https://music.example.com',
          username: 'demo',
          password: 'pw',
        );
    first.dispose();

    final second = buildContainer();
    final state = await second.read(authControllerProvider.future);

    expect(state.servers.single.id, config.id);
    expect(state.servers.single.type, ServerType.navidrome);
    expect(state.currentServerId, config.id);
  });
}
