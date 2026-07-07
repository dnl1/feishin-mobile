import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../domain/domain.dart';
import 'library_providers.dart';
import '../player/player.dart';
import 'widgets/cover_art.dart';
import 'widgets/error_retry.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = ref.watch(albumDetailProvider(albumId));

    return switch (album) {
      AsyncData(:final value) => Scaffold(body: _AlbumDetail(album: value)),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(albumDetailProvider(albumId)),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _AlbumDetail extends ConsumerWidget {
  const _AlbumDetail({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = album.songs ?? const <Song>[];
    final multiDisc = songs.any((song) => song.discNumber > 1);

    final subtitleParts = [
      if (album.releaseYear != null) '${album.releaseYear}',
      if (album.songCount != null) '${album.songCount} músicas',
      if (album.duration != null) formatDurationMs(album.duration),
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 320,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 48,
              end: 48,
              bottom: 16,
            ),
            title: Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: Padding(
              padding: const EdgeInsets.fromLTRB(48, 72, 48, 48),
              child: Center(child: CoverArt(imageId: album.imageId, size: 600)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: album.albumArtists.isNotEmpty
                      ? () => context.push(
                          '/library/artists/${album.albumArtists.first.id}',
                        )
                      : null,
                  child: Text(
                    album.albumArtistName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (album.genres.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final genre in album.genres)
                          ActionChip(
                            label: Text(genre.name),
                            onPressed: () => context.push(
                              Uri(
                                path: '/library/albums-by-genre',
                                queryParameters: {
                                  'genreId': genre.id,
                                  'name': genre.name,
                                },
                              ).toString(),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final showDiscHeader =
                multiDisc &&
                (index == 0 || songs[index - 1].discNumber != song.discNumber);

            final tile = ListTile(
              leading: SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    '${song.trackNumber}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              title: Text(
                song.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: song.artistName != album.albumArtistName
                  ? Text(
                      song.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Text(formatDurationMs(song.duration)),
              onTap: () => ref
                  .read(playerControllerProvider.notifier)
                  .setQueue(songs, index: index),
            );

            if (!showDiscHeader) {
              return tile;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    song.discSubtitle ?? 'Disco ${song.discNumber}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                tile,
              ],
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}
