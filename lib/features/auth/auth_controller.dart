import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/music_server_repository.dart';
import '../../data/navidrome/navidrome_repository.dart';
import '../../domain/domain.dart';
import 'credentials_store.dart';
import 'secure_store.dart';
import 'server_store.dart';

/// Mirrors the state of the original auth store (auth.store.ts): the saved
/// server list plus which one is active.
class AuthState {
  const AuthState({required this.currentServerId, required this.servers});

  final String? currentServerId;
  final List<ServerConfig> servers;

  ServerConfig? get currentServer {
    for (final server in servers) {
      if (server.id == currentServerId) {
        return server;
      }
    }
    return null;
  }
}

/// Overridden in `main` with the Hive box opened during bootstrap.
final serverStoreProvider = Provider<ServerStore>(
  (ref) => throw UnimplementedError('serverStoreProvider must be overridden'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => KeychainSecureStore(),
);

final credentialsStoreProvider = Provider<CredentialsStore>(
  (ref) => CredentialsStore(ref.watch(secureStoreProvider)),
);

typedef AuthenticateFn =
    Future<(ServerAuthResult, ServerInfo?)> Function({
      required String url,
      required String username,
      required String password,
    });

/// Indirection over the static login call so tests can fake the server.
final navidromeAuthenticateProvider = Provider<AuthenticateFn>(
  (ref) => NavidromeRepository.authenticate,
);

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final store = ref.watch(serverStoreProvider);
    return AuthState(
      currentServerId: store.currentServerId,
      servers: store.getServers(),
    );
  }

  /// Logs into a Navidrome server and persists it (config in Hive,
  /// credentials/password in the keychain). The first saved server becomes
  /// the current one automatically.
  Future<ServerConfig> addServer({
    required String name,
    required String url,
    required String username,
    required String password,
    bool savePassword = false,
  }) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    final authenticate = ref.read(navidromeAuthenticateProvider);
    final (auth, info) = await authenticate(
      url: cleanUrl,
      username: username,
      password: password,
    );

    final config = ServerConfig(
      features: info?.features,
      id: _generateId(),
      isAdmin: auth.isAdmin,
      name: name,
      savePassword: savePassword,
      type: ServerType.navidrome,
      url: cleanUrl,
      userId: auth.userId,
      username: auth.username,
      version: info?.version,
    );

    final serverStore = ref.read(serverStoreProvider);
    final credentialsStore = ref.read(credentialsStoreProvider);

    await credentialsStore.setCredentials(config.id, auth.credentials);
    if (savePassword) {
      await credentialsStore.setPassword(config.id, password);
    }
    await serverStore.upsertServer(config);
    if (serverStore.currentServerId == null) {
      await serverStore.setCurrentServerId(config.id);
    }

    await _reload();
    return config;
  }

  Future<void> deleteServer(String id) async {
    await ref.read(credentialsStoreProvider).deleteServer(id);
    await ref.read(serverStoreProvider).deleteServer(id);
    await _reload();
  }

  Future<void> setCurrentServer(String? id) async {
    await ref.read(serverStoreProvider).setCurrentServerId(id);
    await _reload();
  }

  /// Re-login with the stored password after a 401 (token expired). Returns
  /// null when re-auth is impossible (password not saved / login rejected) —
  /// the caller then surfaces the original 401.
  Future<ServerCredentials?> reauthenticate(String serverId) async {
    final server = ref.read(serverStoreProvider).getServer(serverId);
    if (server == null || server.savePassword != true) {
      return null;
    }

    final credentialsStore = ref.read(credentialsStoreProvider);
    final password = await credentialsStore.getPassword(serverId);
    if (password == null) {
      return null;
    }

    try {
      final (auth, _) = await ref.read(navidromeAuthenticateProvider)(
        url: server.url,
        username: server.username,
        password: password,
      );
      await credentialsStore.setCredentials(serverId, auth.credentials);
      return auth.credentials;
    } on Exception {
      return null;
    }
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  static String _generateId() {
    final random = Random.secure();
    return List.generate(
      21,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
