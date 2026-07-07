import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/queries.dart';
import '../../data/repository_provider.dart';
import '../auth/auth_controller.dart';

typedef LibraryStats = ({int albums, int artists, int songs});

/// Smoke-test of the whole phase-1 stack against the real server: three
/// count queries through auth → API → normalizer. Replaced by the actual
/// library screens in phase 2.
final libraryStatsProvider = FutureProvider<LibraryStats?>((ref) async {
  final repository = await ref.watch(musicServerRepositoryProvider.future);
  if (repository == null) {
    return null;
  }

  final albums = await repository.getAlbumListCount(const AlbumListQuery());
  final artists = await repository.getAlbumArtistListCount(
    const AlbumArtistListQuery(),
  );
  final songs = await repository.getSongListCount(const SongListQuery());

  return (albums: albums, artists: artists, songs: songs);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final stats = ref.watch(libraryStatsProvider);
    final server = auth.value?.currentServer;

    return Scaffold(
      appBar: AppBar(
        title: Text(server?.name ?? 'Feishin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Servidores',
            onPressed: () => context.go('/servers'),
          ),
        ],
      ),
      body: Center(
        child: switch (stats) {
          AsyncData(:final value) when value != null => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conectado a ${server?.url ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '${value.albums} álbuns · ${value.artists} artistas · '
                '${value.songs} músicas',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Biblioteca completa chega na Fase 2.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Falha ao consultar o servidor:\n$error',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(libraryStatsProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          _ => const CircularProgressIndicator(),
        },
      ),
    );
  }
}
