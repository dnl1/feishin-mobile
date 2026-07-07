import 'dart:convert';

import '../../domain/server.dart';
import 'secure_store.dart';

/// Keychain-backed storage for the secret half of a server entry.
///
/// The original app kept credentials in localStorage next to the config
/// (auth.store.ts) and only the optional password in safeStorage; here both
/// credentials and password live in the keychain, keyed by server id
/// (see PLAN.md, phase 1).
class CredentialsStore {
  const CredentialsStore(this._store);

  final SecureStore _store;

  static String _credentialsKey(String serverId) => 'credentials:$serverId';
  static String _passwordKey(String serverId) => 'password:$serverId';

  Future<ServerCredentials?> getCredentials(String serverId) async {
    final raw = await _store.read(_credentialsKey(serverId));
    if (raw == null) {
      return null;
    }

    return ServerCredentials.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setCredentials(String serverId, ServerCredentials credentials) =>
      _store.write(_credentialsKey(serverId), jsonEncode(credentials));

  /// Stored only when the user opts into "save password" — enables silent
  /// re-login when the Navidrome token expires.
  Future<String?> getPassword(String serverId) =>
      _store.read(_passwordKey(serverId));

  Future<void> setPassword(String serverId, String password) =>
      _store.write(_passwordKey(serverId), password);

  Future<void> deleteServer(String serverId) async {
    await _store.delete(_credentialsKey(serverId));
    await _store.delete(_passwordKey(serverId));
  }
}
