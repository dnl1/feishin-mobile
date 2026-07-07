import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/server.dart';
import '../features/auth/auth_controller.dart';
import 'music_server_repository.dart';
import 'navidrome/navidrome_api.dart';
import 'navidrome/navidrome_repository.dart';

/// Repository for the current server, or null when no server is selected.
/// Rebuilt whenever the auth state changes (server switched/removed).
final musicServerRepositoryProvider = FutureProvider<MusicServerRepository?>((
  ref,
) async {
  final auth = await ref.watch(authControllerProvider.future);
  final server = auth.currentServer;
  if (server == null) {
    return null;
  }

  final credentialsStore = ref.watch(credentialsStoreProvider);
  ServerCredentials? credentials = await credentialsStore.getCredentials(
    server.id,
  );

  final api = NavidromeApi(
    serverUrl: server.url,
    tokenProvider: () => credentials?.ndCredential,
    onTokenRefreshed: (token) {
      final current = credentials;
      if (current == null || current.ndCredential == token) {
        return;
      }
      final rotated = current.copyWith(ndCredential: token);
      credentials = rotated;
      // Persist the rotated token so the next launch reuses it. Mirrors the
      // x-nd-authorization capture in the original response interceptor.
      unawaited(credentialsStore.setCredentials(server.id, rotated));
    },
    reauthenticate: () async {
      final fresh = await ref
          .read(authControllerProvider.notifier)
          .reauthenticate(server.id);
      if (fresh == null) {
        return null;
      }
      credentials = fresh;
      return fresh.ndCredential;
    },
  );

  return NavidromeRepository(
    server: server,
    api: api,
    subsonicCredential: () => credentials?.credential,
  );
});
