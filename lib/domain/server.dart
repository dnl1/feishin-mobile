import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'server.freezed.dart';
part 'server.g.dart';

/// Mirrors the non-secret fields of `ServerListItem` in
/// feishin/src/shared/types/domain-types.ts.
///
/// Split from [ServerCredentials] on purpose: this goes in Hive/
/// shared_preferences, credentials go in flutter_secure_storage (Keychain)
/// — see plan phase 1. The original app kept them together in one
/// localStorage-persisted zustand store.
@freezed
abstract class ServerConfig with _$ServerConfig {
  const factory ServerConfig({
    Map<String, dynamic>? features,
    required String id,
    bool? isAdmin,
    List<String>? musicFolderId,
    required String name,
    bool? preferInstantMix,
    bool? preferRemoteUrl,
    String? remoteUrl,
    bool? savePassword,
    required ServerType type,
    required String url,
    required String? userId,
    required String username,
    String? version,
  }) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);
}

/// Mirrors the secret fields added by `ServerListItemWithCredential` in
/// feishin/src/shared/types/domain-types.ts. Stored in flutter_secure_storage
/// keyed by [ServerConfig.id], never alongside the non-secret config.
@freezed
abstract class ServerCredentials with _$ServerCredentials {
  const factory ServerCredentials({
    required String credential,
    String? ndCredential,
  }) = _ServerCredentials;

  factory ServerCredentials.fromJson(Map<String, dynamic> json) =>
      _$ServerCredentialsFromJson(json);
}
