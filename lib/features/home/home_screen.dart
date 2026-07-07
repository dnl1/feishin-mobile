import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/queries.dart';
import '../../data/repository_provider.dart';
import '../auth/auth_controller.dart';

typedef LibraryStats = ({int albums, int artists, int songs});

/// Library overview via three count queries (auth → API → normalizer
/// against the real server).
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
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Tema',
            onPressed: () => context.push('/settings/theme'),
          ),
          IconButton(
            icon: const Icon(Icons.language_outlined),
            tooltip: 'Idioma',
            onPressed: () => context.push('/settings/language'),
          ),
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Servidores',
            onPressed: () => context.push('/servers'),
          ),
        ],
      ),
      body: switch (stats) {
        AsyncData(:final value) when value != null => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Conectado a ${server?.url ?? ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            _StatCard(
              icon: Icons.album,
              label: 'Álbuns',
              count: value.albums,
              location: '/library/albums',
            ),
            _StatCard(
              icon: Icons.person,
              label: 'Artistas',
              count: value.artists,
              location: '/library/artists',
            ),
            _StatCard(
              icon: Icons.music_note,
              label: 'Músicas',
              count: value.songs,
              location: '/library/songs',
            ),
          ],
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Falha ao consultar o servidor:\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(libraryStatsProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.count,
    required this.icon,
    required this.label,
    required this.location,
  });

  final int count;
  final IconData icon;
  final String label;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: () => context.go(location),
      ),
    );
  }
}
