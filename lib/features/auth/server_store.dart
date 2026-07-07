import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/server.dart';

/// Hive-backed storage for the non-secret server list + current selection,
/// replacing the localStorage-persisted zustand auth store of the original
/// app. Secrets never go here — see [CredentialsStore].
class ServerStore {
  const ServerStore(this._box);

  static const String boxName = 'servers';
  static const String _currentServerKey = '_currentServerId';
  static const String _serverPrefix = 'server:';

  final Box<String> _box;

  List<ServerConfig> getServers() {
    return _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(_serverPrefix))
        .map((key) => _decode(_box.get(key)!))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  ServerConfig? getServer(String id) {
    final raw = _box.get('$_serverPrefix$id');
    return raw == null ? null : _decode(raw);
  }

  Future<void> upsertServer(ServerConfig config) =>
      _box.put('$_serverPrefix${config.id}', jsonEncode(config));

  Future<void> deleteServer(String id) async {
    await _box.delete('$_serverPrefix$id');
    if (currentServerId == id) {
      await setCurrentServerId(null);
    }
  }

  String? get currentServerId => _box.get(_currentServerKey);

  Future<void> setCurrentServerId(String? id) => id == null
      ? _box.delete(_currentServerKey)
      : _box.put(_currentServerKey, id);

  static ServerConfig _decode(String raw) =>
      ServerConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
