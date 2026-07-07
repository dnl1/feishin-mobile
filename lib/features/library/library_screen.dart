import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Library entry menu — the browse sections land as sub-routes.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: ListView(
        children: const [
          _LibraryTile(
            icon: Icons.album,
            label: 'Álbuns',
            location: '/library/albums',
          ),
          _LibraryTile(
            icon: Icons.person,
            label: 'Artistas',
            location: '/library/artists',
          ),
          _LibraryTile(
            icon: Icons.music_note,
            label: 'Músicas',
            location: '/library/songs',
          ),
          _LibraryTile(
            icon: Icons.label_outline,
            label: 'Gêneros',
            location: '/library/genres',
          ),
          _LibraryTile(
            icon: Icons.queue_music,
            label: 'Playlists',
            location: '/library/playlists',
          ),
          _LibraryTile(
            icon: Icons.radio,
            label: 'Rádios',
            location: '/library/radios',
          ),
        ],
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.icon,
    required this.label,
    required this.location,
  });

  final IconData icon;
  final String label;
  final String location;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(location),
    );
  }
}
