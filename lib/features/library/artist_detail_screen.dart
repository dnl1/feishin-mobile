import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/queries.dart';
import '../../domain/domain.dart';
import 'library_providers.dart';
import 'widgets/cover_art.dart';
import 'widgets/error_retry.dart';
import 'widgets/paged_scroll.dart';

/// Artist page: header + discography (albums sorted by year, newest first).
class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artistId});

  final String artistId;

  AlbumsArg get _albumsArg => (
    artistId: artistId,
    genreId: null,
    sortBy: AlbumListSort.year,
    sortOrder: SortOrder.desc,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = ref.watch(artistDetailProvider(artistId));
    final albums = ref.watch(albumListControllerProvider(_albumsArg));

    return Scaffold(
      appBar: AppBar(title: Text(artist.value?.name ?? '')),
      body: switch (artist) {
        AsyncData(:final value) => PagedScrollListener(
          onLoadMore: () => ref
              .read(albumListControllerProvider(_albumsArg).notifier)
              .loadMore(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _ArtistHeader(artist: value)),
              switch (albums) {
                AsyncData(:final value) => SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: value.items.length,
                    itemBuilder: (context, index) {
                      final album = value.items[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            context.push('/library/albums/${album.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CoverArt(imageId: album.imageId, size: 300),
                            const SizedBox(height: 6),
                            Text(
                              album.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (album.releaseYear != null)
                              Text(
                                '${album.releaseYear}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                AsyncError(:final error) => SliverToBoxAdapter(
                  child: ErrorRetry(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(albumListControllerProvider(_albumsArg)),
                  ),
                ),
                _ => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              },
              SliverToBoxAdapter(
                child: LoadMoreFooter(
                  isLoading: albums.value?.isLoadingMore ?? false,
                  failed: albums.value?.loadMoreFailed ?? false,
                  onRetry: () => ref
                      .read(albumListControllerProvider(_albumsArg).notifier)
                      .loadMore(),
                ),
              ),
            ],
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(artistDetailProvider(artistId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ArtistHeader extends StatelessWidget {
  const _ArtistHeader({required this.artist});

  final AlbumArtist artist;

  @override
  Widget build(BuildContext context) {
    final counts = [
      if (artist.albumCount != null) '${artist.albumCount} álbuns',
      if (artist.songCount != null) '${artist.songCount} músicas',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: CoverArt(
              imageId: artist.imageId,
              size: 300,
              borderRadius: 48,
              fallbackIcon: Icons.person,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (counts.isNotEmpty)
                  Text(
                    counts.join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                if (artist.biography != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      artist.biography!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
