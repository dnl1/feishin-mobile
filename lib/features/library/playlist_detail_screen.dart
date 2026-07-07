import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import 'library_providers.dart';
import 'songs_screen.dart';
import 'widgets/cover_art.dart';
import 'widgets/error_retry.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistDetailProvider(playlistId));
    final songs = ref.watch(playlistSongsProvider(playlistId));

    return Scaffold(
      appBar: AppBar(title: Text(playlist.value?.name ?? '')),
      body: switch ((playlist, songs)) {
        (AsyncError(:final error), _) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(playlistDetailProvider(playlistId)),
        ),
        (_, AsyncError(:final error)) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(playlistSongsProvider(playlistId)),
        ),
        (AsyncData(value: final detail), AsyncData(value: final items)) =>
          RefreshIndicator(
            onRefresh: () {
              ref.invalidate(playlistDetailProvider(playlistId));
              ref.invalidate(playlistSongsProvider(playlistId));
              return ref.read(playlistSongsProvider(playlistId).future);
            },
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: CoverArt(
                          imageId: detail.imageId,
                          size: 300,
                          fallbackIcon: Icons.queue_music,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              [
                                '${items.length} músicas',
                                if (detail.duration != null)
                                  formatDurationMs(detail.duration),
                                if (detail.owner != null) detail.owner!,
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                            if (detail.description != null &&
                                detail.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  detail.description!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (final song in items) SongTile(song: song),
                const SizedBox(height: 24),
              ],
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
